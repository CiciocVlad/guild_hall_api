defmodule GuildHall.Controllers.UsersPTOTest do
  use GuildHallWeb.ConnCase

  describe "without authorisation" do
    test_returns_401("user_path(:get_off_today)", fn conn ->
      post(conn, Routes.user_path(conn, :get_off_today, %{email: "some email"}))
    end)

    test_returns_401("user_path(:remaining_days)", fn conn ->
      get(conn, Routes.user_path(conn, :remaining_days))
    end)

    test_returns_401("user_path(:list_users)", fn conn ->
      get(conn, Routes.user_path(conn, :list_users))
    end)
  end

  defp create_user_pto(%{user: user}) do
    Factory.insert(:pto, days: 15, year: Date.utc_today().year, user_id: user.id)

    :ok
  end

  defp add_bypass(_context) do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"
    Application.put_env(:goth, :endpoint, bypass_url)
    Application.put_env(:goth, :metadata_url, bypass_url)

    Application.put_env(:guild_hall, GuildHall.PTODays.PTOBackendGoogleCalendar,
      base_url: bypass_url,
      calendars: %{
        pto: "off",
        bonus_pto: "off-bonus",
        extra: "add-days",
        legal: "legal"
      },
      time_zone: "Europe/Bucharest"
    )

    Application.put_env(:guild_hall, :pto_backend, GuildHall.PTODays.PTOBackendGoogleCalendar)

    {:ok, bypass: bypass}
  end

  defp bypass_google_oauth(context) do
    %{bypass: bypass} = context

    google_oauth_token = "some-access-token"

    Bypass.stub(bypass, "POST", "/oauth2/v4/token", fn conn ->
      conn
      |> Plug.Conn.resp(
        201,
        Jason.encode!(%{
          "access_token" => google_oauth_token,
          "token_type" => "Bearer",
          "expires_in" => 3600
        })
      )
    end)

    {:ok, google_oauth_token: google_oauth_token}
  end

  describe "user_path(:get_off_today)" do
    setup [
      :create_and_authorise_user,
      :create_user_pto,
      :add_bypass,
      :bypass_google_oauth
    ]

    for calendar_name <- ["off", "off-bonus"] do
      test "returns an event matching the email from the #{calendar_name} calendar", %{
        bypass: bypass,
        google_oauth_token: google_oauth_token,
        conn: conn
      } do
        %{email: email} = Factory.build(:user)

        items_for_this_email = [
          Factory.build(:google_event, %{
            "creator" => %{"email" => email},
            "start" => %{"date" => ~D[2022-02-02]},
            "end" => %{"date" => ~D[2022-03-03]}
          }),
          Factory.build(:google_event, %{
            "creator" => %{"email" => email},
            "start" => %{"date" => ~D[2022-03-28]},
            "end" => %{"date" => ~D[2022-04-01]}
          })
        ]

        for cal <- ["off", "off-bonus"] do
          Bypass.expect_once(bypass, "GET", "/#{cal}/events", fn conn ->
            assert conn.query_params == %{
                     "maxResults" => "2500",
                     "timeMin" =>
                       Date.utc_today()
                       |> DateTime.new!(~T[00:00:00], "Europe/Bucharest")
                       |> DateTime.to_iso8601(),
                     "timeMax" =>
                       Date.utc_today()
                       |> Date.add(1)
                       |> DateTime.new!(~T[00:00:00], "Europe/Bucharest")
                       |> DateTime.to_iso8601(),
                     "singleEvents" => "true"
                   }

            assert {"authorization", "Bearer " <> actual_token} =
                     Enum.find(conn.req_headers, fn {k, _v} -> k == "authorization" end)

            assert actual_token == google_oauth_token

            response =
              :google_events_response
              |> Factory.build()
              |> Map.update("items", items_for_this_email, fn items ->
                items ++ if(unquote(calendar_name) == cal, do: items_for_this_email, else: [])
              end)

            conn
            |> Plug.Conn.resp(200, Jason.encode!(response))
          end)
        end

        conn =
          conn
          |> post(Routes.user_path(conn, :get_off_today, %{email: email}))

        assert json_response(conn, 200) in [
                 %{
                   "end" => "2022-03-02",
                   "off_today" => true,
                   "start" => "2022-02-03"
                 },
                 %{
                   "end" => "2022-03-31",
                   "off_today" => true,
                   "start" => "2022-03-28"
                 }
               ]
      end
    end

    test "returns {'off_today': false} when no calendar item matches the email", %{
      bypass: bypass,
      conn: conn
    } do
      %{email: email} = Factory.build(:user)

      for cal <- ["off", "off-bonus"] do
        Bypass.expect_once(bypass, "GET", "/#{cal}/events", fn conn ->
          conn
          |> Plug.Conn.resp(200, Jason.encode!(Factory.build(:google_events_response)))
        end)
      end

      conn =
        conn
        |> post(Routes.user_path(conn, :get_off_today, %{email: email}))

      assert json_response(conn, 200) == %{
               "off_today" => false
             }
    end

    test "returns a 500 when the calendar url returns a 500", %{bypass: bypass, conn: conn} do
      %{email: email} = Factory.build(:user)

      for cal <- ["off", "off-bonus"] do
        Bypass.stub(bypass, "GET", "/#{cal}/events", fn conn ->
          conn
          |> Plug.Conn.resp(500, Jason.encode!(%{"error" => "error message"}))
        end)
      end

      assert conn
             |> post(Routes.user_path(conn, :get_off_today, %{email: email}))
             |> json_response(500)
    end

    test "returns a 500 when the calendar auth fails", %{bypass: bypass, conn: conn} do
      %{email: email} = Factory.build(:user)

      Bypass.stub(bypass, "POST", "/oauth2/v4/token", fn conn ->
        conn
        |> Plug.Conn.resp(
          500,
          Jason.encode!(%{"error" => "some error"})
        )
      end)

      # Goth caches the token, restarting the app should empty the cache
      :ok = Application.stop(:goth)
      :ok = Application.ensure_started(:goth)

      assert conn
             |> post(Routes.user_path(conn, :get_off_today, %{email: email}))
             |> json_response(500)
    end
  end

  def bypass_google_legal_holidays(%{bypass: bypass}) do
    Bypass.stub(
      bypass,
      "GET",
      "/ro.romanian.official%23holiday%40group.v.calendar.google.com/events",
      fn conn ->
        legal_holidays =
          for date <- [~D[2022-12-25], ~D[2022-12-26], ~D[2023-01-01], ~D[2023-01-02]] do
            Factory.build(:google_event, %{
              "start" => %{"date" => date},
              "end" => %{"date" => date}
            })
          end

        conn
        |> Plug.Conn.resp(
          200,
          :google_events_response
          |> Factory.build()
          |> Map.put("items", legal_holidays)
          |> Jason.encode!()
        )
      end
    )
  end

  describe "user_path(:remaining_days)" do
    setup [
      :create_and_authorise_user,
      :create_user_pto,
      :add_bypass,
      :bypass_google_oauth,
      :bypass_google_legal_holidays
    ]

    test "returns the nominal number of remaining days when there are no matching events", %{
      bypass: bypass,
      conn: conn,
      google_oauth_token: google_oauth_token
    } do
      for cal <- ["off", "add-days", "legal", "off-bonus"] do
        Bypass.expect_once(bypass, "GET", "/#{cal}/events", fn conn ->
          assert conn.query_params == %{
                   "maxResults" => "2500",
                   "timeMin" =>
                     Date.new!(Date.utc_today().year, 1, 1)
                     |> DateTime.new!(~T[00:00:00], "Europe/Bucharest")
                     |> DateTime.to_iso8601(),
                   "timeMax" =>
                     Date.new!(Date.utc_today().year + 1, 1, 1)
                     |> DateTime.new!(~T[00:00:00], "Europe/Bucharest")
                     |> DateTime.to_iso8601(),
                   "singleEvents" => "true"
                 }

          assert {"authorization", "Bearer " <> actual_token} =
                   Enum.find(conn.req_headers, fn {k, _v} -> k == "authorization" end)

          assert actual_token == google_oauth_token

          conn
          |> Plug.Conn.resp(200, Jason.encode!(Factory.build(:google_events_response)))
        end)
      end

      conn =
        conn
        |> get(Routes.user_path(conn, :remaining_days))

      assert json_response(conn, 200) == %{
               "days_extra" => 0,
               "days_off" => 15,
               "events" => [],
               "remaining_days" => 15,
               "taken_days" => 0,
               "add_days" => [],
               "bonus_days" => [],
               "past_days" => []
             }
    end

    defp google_events_response(conn, email, dates) do
      items_for_this_email =
        for {start_date, end_date} <- dates do
          Factory.build(:google_event, %{
            "creator" => %{"email" => email},
            "start" => %{"date" => start_date},
            "end" => %{"date" => end_date}
          })
        end

      conn
      |> Plug.Conn.resp(
        200,
        :google_events_response
        |> Factory.build()
        |> Map.update("items", items_for_this_email, fn items ->
          items ++ items_for_this_email
        end)
        |> Jason.encode!()
      )
    end

    defp google_events_legal_holidays_response(conn, year) do
      conn
      |> Plug.Conn.resp(
        200,
        :google_events_response_legal_holidays
        |> Factory.build(%{year: year})
        |> Jason.encode!()
      )
    end

    test "computes the number of remaining days based on the returned events", %{
      user: user,
      bypass: bypass,
      conn: conn
    } do
      Bypass.expect_once(bypass, "GET", "/off/events", fn conn ->
        google_events_response(conn, user.email, [
          {~D[2021-12-30], ~D[2022-01-03]},
          {~D[2022-02-28], ~D[2022-03-02]},
          {~D[2022-06-27], ~D[2022-07-04]},
          {~D[2022-08-28], ~D[2022-09-01]},
          {~D[2022-12-02], ~D[2022-12-03]},
          {~D[2022-12-23], ~D[2023-01-05]}
        ])
      end)

      Bypass.expect_once(bypass, "GET", "/off-bonus/events", fn conn ->
        google_events_response(conn, user.email, [])
      end)

      Bypass.expect_once(bypass, "GET", "/add-days/events", fn conn ->
        google_events_response(conn, user.email, [
          {~D[2022-01-02], ~D[2022-01-03]},
          {~D[2022-06-25], ~D[2022-06-27]},
          {~D[2022-08-15], ~D[2022-08-16]},
          {~D[2022-11-30], ~D[2022-12-02]}
        ])
      end)

      Bypass.expect_once(bypass, "GET", "/legal/events", fn conn ->
        google_events_legal_holidays_response(conn, Date.utc_today().year)
      end)

      conn =
        conn
        |> get(Routes.user_path(conn, :remaining_days))

      assert json_response(conn, 200) == %{
               "days_extra" => 6,
               "days_off" => 15,
               "events" => [
                 %{"end" => "2022-01-02", "number_of_days" => 0, "start" => "2021-12-30"},
                 %{"end" => "2022-03-01", "number_of_days" => 2, "start" => "2022-02-28"},
                 %{"end" => "2022-07-03", "number_of_days" => 5, "start" => "2022-06-27"},
                 %{"end" => "2022-08-31", "number_of_days" => 3, "start" => "2022-08-28"},
                 %{"end" => "2022-12-02", "number_of_days" => 1, "start" => "2022-12-02"},
                 %{"end" => "2023-01-04", "number_of_days" => 5, "start" => "2022-12-23"}
               ],
               "remaining_days" => 15 - 16 + 6,
               "taken_days" => 16,
               "add_days" => [
                 %{"end" => "2022-01-02", "number_of_days" => 1, "start" => "2022-01-02"},
                 %{"end" => "2022-06-26", "number_of_days" => 2, "start" => "2022-06-25"},
                 %{"end" => "2022-08-15", "number_of_days" => 1, "start" => "2022-08-15"},
                 %{"end" => "2022-12-01", "number_of_days" => 2, "start" => "2022-11-30"}
               ],
               "bonus_days" => [],
               "past_days" => []
             }
    end

    test "returns a 500 when the calendar auth fails", %{bypass: bypass, conn: conn} do
      Bypass.stub(bypass, "POST", "/oauth2/v4/token", fn conn ->
        conn
        |> Plug.Conn.resp(
          500,
          Jason.encode!(%{"error" => "some error"})
        )
      end)

      # Goth caches the token, restarting the app should empty the cache
      :ok = Application.stop(:goth)
      :ok = Application.ensure_started(:goth)

      assert conn
             |> get(Routes.user_path(conn, :remaining_days))
             |> json_response(500)
    end
  end

  describe "user_path(:list_users)" do
    setup [:create_and_authorise_user, :create_user_pto, :add_bypass, :bypass_google_oauth]

    for calendars <- [["off"], ["off-bonus"], ["off", "off-bonus"]] do
      test "sets :is_working to false when there are events for the user in #{inspect(calendars)}",
           %{
             user: user,
             bypass: bypass,
             conn: conn
           } do
        for cal <- ["off", "off-bonus"] do
          Bypass.expect_once(bypass, "GET", "/#{cal}/events", fn conn ->
            events =
              if cal in unquote(calendars) do
                [{~D[2021-12-30], ~D[2022-01-02]}]
              else
                []
              end

            google_events_response(conn, user.email, events)
          end)
        end

        conn =
          conn
          |> get(Routes.user_path(conn, :list_users))

        assert [%{"is_working" => false}] = json_response(conn, 200)
      end
    end

    test "sets :is_working to true when there aren't any events for the users",
         %{
           user: user,
           bypass: bypass,
           conn: conn
         } do
      for cal <- ["off", "off-bonus"] do
        Bypass.expect_once(bypass, "GET", "/#{cal}/events", fn conn ->
          google_events_response(conn, user.email, [])
        end)
      end

      conn =
        conn
        |> get(Routes.user_path(conn, :list_users))

      assert [%{"is_working" => true}] = json_response(conn, 200)
    end

    test "returns a 500 when the calendar auth fails", %{bypass: bypass, conn: conn} do
      Bypass.stub(bypass, "POST", "/oauth2/v4/token", fn conn ->
        conn
        |> Plug.Conn.resp(
          500,
          Jason.encode!(%{"error" => "some error"})
        )
      end)

      # Goth caches the token, restarting the app should empty the cache
      :ok = Application.stop(:goth)
      :ok = Application.ensure_started(:goth)

      assert conn
             |> get(Routes.user_path(conn, :list_users))
             |> json_response(500)
    end
  end
end
