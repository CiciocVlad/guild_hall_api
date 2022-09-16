defmodule GuildHall.PTODays.PTOBackendGoogleCalendarTest do
  use GuildHall.DataCase

  alias GuildHall.PTODays.PTOBackendGoogleCalendar

  setup_all do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"
    Application.put_env(:goth, :endpoint, bypass_url)
    Application.put_env(:goth, :metadata_url, bypass_url)

    {:ok, bypass: bypass, bypass_url: bypass_url}
  end

  defp bypass_google_auth(context) do
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

  describe "success" do
    setup :bypass_google_auth

    test "authenticates and forwards the call to a Google Calendar", %{
      bypass: bypass,
      bypass_url: bypass_url,
      google_oauth_token: google_oauth_token
    } do
      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        assert conn.query_params == %{
                 "maxResults" => "10",
                 "timeMin" =>
                   ~D[2020-01-14]
                   |> DateTime.new!(~T[00:00:00], "Europe/London")
                   |> DateTime.to_iso8601(),
                 "timeMax" =>
                   ~D[2022-01-01]
                   |> DateTime.new!(~T[00:00:00], "Europe/London")
                   |> DateTime.to_iso8601(),
                 "singleEvents" => "true"
               }

        assert {"authorization", "Bearer " <> actual_token} =
                 Enum.find(conn.req_headers, fn {k, _v} -> k == "authorization" end)

        assert actual_token == google_oauth_token

        response =
          :google_events_response
          |> Factory.build()
          |> Map.put("items", [])

        conn
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok, []} ==
               PTOBackendGoogleCalendar.list(
                 start_date: ~D[2020-01-14],
                 end_date: ~D[2021-12-31],
                 max_results: 10,
                 type: :pto,
                 config: [
                   base_url: bypass_url,
                   calendars: %{pto: "pto"},
                   time_zone: "Europe/London"
                 ]
               )
    end

    test "parses the results, ignores DateTime start/end dates and filters by :creator_email",
         %{
           bypass: bypass,
           bypass_url: bypass_url
         } do
      email = "this_email@right.now"

      items_for_this_email = [
        Factory.build(:google_event, %{
          "created" => ~U[2020-12-31T23:59:59Z],
          "updated" => ~U[2021-01-01T00:00:01Z],
          "summary" => "last year's item",
          "creator" => %{
            "email" => email
          },
          "start" => %{
            "date" => ~D[2020-12-01]
          },
          "end" => %{
            "date" => ~D[2020-12-18]
          }
        }),
        Factory.build(:google_event, %{
          "created" => ~U[2020-12-31T23:59:59Z],
          "updated" => ~U[2021-01-01T00:00:01Z],
          "summary" => "last year's item (datetime)",
          "creator" => %{
            "email" => email
          },
          "start" => %{
            "dateTime" => ~U[2020-12-01T10:20:30Z]
          },
          "end" => %{
            "dateTime" => ~U[2020-12-01T11:20:30Z]
          }
        })
      ]

      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        response =
          :google_events_response
          |> Factory.build()
          |> Map.update("items", items_for_this_email, fn items ->
            items ++ items_for_this_email
          end)

        conn
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok,
              [
                %{
                  creator_email: email,
                  start_date: ~D[2020-12-01],
                  # the end date in the Google Calendar API is exclusive,
                  # but this API needs it inclusive so subtracting one day
                  end_date: ~D[2020-12-17],
                  created_at: ~U[2020-12-31T23:59:59Z],
                  updated_at: ~U[2021-01-01T00:00:01Z],
                  summary: "last year's item"
                }
              ]} ==
               PTOBackendGoogleCalendar.list(
                 creator_email: email,
                 start_date: ~D[2020-01-14],
                 end_date: ~D[2021-12-30],
                 type: :pto,
                 config: [
                   base_url: bypass_url,
                   calendars: %{pto: "pto"},
                   time_zone: "Europe/Bucharest"
                 ]
               )
    end

    test "rejects some legal holidays",
         %{
           bypass: bypass,
           bypass_url: bypass_url
         } do
      Bypass.expect_once(bypass, "GET", "/legal/events", fn conn ->
        response =
          :google_events_response_legal_holidays
          |> Factory.build(%{year: 2022})

        conn
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok, results} =
               PTOBackendGoogleCalendar.list(
                 start_date: ~D[2022-01-14],
                 end_date: ~D[2022-12-30],
                 type: :legal,
                 config: [
                   base_url: bypass_url,
                   calendars: %{legal: "legal"},
                   time_zone: "Europe/Bucharest"
                 ]
               )

      refute Enum.find(results, fn item ->
               String.contains?(item[:summary], "Sectorul Public") or
                 String.contains?(item[:summary], "Ajunul Crăciunului")
             end)
    end

    test "reads config from Application env", %{bypass: bypass, bypass_url: bypass_url} do
      Application.put_env(:guild_hall, GuildHall.PTODays.PTOBackendGoogleCalendar,
        base_url: bypass_url,
        calendars: %{pto: "pto"},
        time_zone: "Etc/UTC"
      )

      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        response =
          :google_events_response
          |> Factory.build()

        conn
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok, _items} = PTOBackendGoogleCalendar.list(type: :pto)
    end
  end

  describe "error (config)" do
    test "raises on missing base_url" do
      assert_raise(
        ArgumentError,
        """
        Missing :base_url for GuildHall.PTODays.PTOBackendGoogleCalendar; please configure it, for example:

        \tconfig app_name, GuildHall.PTODays.PTOBackendGoogleCalendar,
        \t    base_url: "https://www.googleapis.com/calendar/v3/calendars"
        """,
        fn ->
          PTOBackendGoogleCalendar.list(config: [])
        end
      )
    end

    test "raises on a base_url without a scheme or host" do
      assert_raise(
        ArgumentError,
        """
        Cannot use the :base_url set for GuildHall.PTODays.PTOBackendGoogleCalendar: 'test.com'

        \tPlease set it to a full URL, including the scheme, for example:

        \tconfig app_name, GuildHall.PTODays.PTOBackendGoogleCalendar,
        \t    base_url: "https://www.googleapis.com/calendar/v3/calendars"
        """,
        fn ->
          PTOBackendGoogleCalendar.list(config: [base_url: "test.com"])
        end
      )
    end

    test "raises on missing :time_zone" do
      assert_raise(
        ArgumentError,
        """
        Missing or empty :time_zone for GuildHall.PTODays.PTOBackendGoogleCalendar; please configure it, for example:

        \tconfig app_name, GuildHall.PTODays.PTOBackendGoogleCalendar,
        \t    time_zone: "Europe/Bucharest"
        """,
        fn ->
          PTOBackendGoogleCalendar.list(config: [base_url: "http://test"])
        end
      )
    end

    test "raises on a empty :calendars mapping" do
      assert_raise(
        ArgumentError,
        """
        Missing or empty :calendars for GuildHall.PTODays.PTOBackendGoogleCalendar; please configure it, for example:

        \tconfig app_name, GuildHall.PTODays.PTOBackendGoogleCalendar,
        \t    calendars: %{
        \t        legal: "ro.romanian.official%23holiday%40group.v.calendar.google.com",
        \t        pto: "pto-calendar-id",
        \t        bonus_pto: "bonus-pto-calendar-id",
        \t        extra: "extra-days-calendar-id"
        \t    }
        """,
        fn ->
          PTOBackendGoogleCalendar.list(config: [base_url: "http://test", time_zone: "Etc/UTC"])
        end
      )
    end

    test "raises on missing or unknown type" do
      assert_raise ArgumentError, "Must set a :type filter", fn ->
        PTOBackendGoogleCalendar.list(
          start_date: ~D[2020-01-14],
          end_date: ~D[2021-12-31],
          config: [base_url: "http://url", calendars: %{pto: "pto"}, time_zone: "Europe/Helsinki"]
        )
      end

      assert_raise ArgumentError, "Results type ':new_type' is not supported", fn ->
        PTOBackendGoogleCalendar.list(
          start_date: ~D[2020-01-14],
          end_date: ~D[2021-12-31],
          type: :new_type,
          config: [base_url: "http://url", calendars: %{pto: "pto"}, time_zone: "Europe/Helsinki"]
        )
      end
    end
  end

  describe "error" do
    setup :bypass_google_auth

    test "returns an error on auth error", %{bypass: bypass, bypass_url: bypass_url} do
      # Goth caches the token, restarting the app should empty the cache
      :ok = Application.stop(:goth)
      :ok = Application.ensure_started(:goth)

      Bypass.stub(bypass, "POST", "/oauth2/v4/token", fn conn ->
        conn
        |> Plug.Conn.resp(
          500,
          Jason.encode!(%{
            "error" => "error"
          })
        )
      end)

      assert {:error, {:get_token, _error}} =
               PTOBackendGoogleCalendar.list(
                 type: :pto,
                 config: [base_url: bypass_url, calendars: %{pto: "pto"}, time_zone: "Etc/UTC"]
               )
    end

    test "returns an error on retrieve error", %{bypass: bypass, bypass_url: bypass_url} do
      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        conn
        |> Plug.Conn.resp(401, Jason.encode!(%{"error" => "some error"}))
      end)

      assert {:error, {:get_calendar_data, _error}} =
               PTOBackendGoogleCalendar.list(
                 type: :pto,
                 config: [
                   base_url: bypass_url,
                   calendars: %{pto: "pto"},
                   time_zone: "Europe/Bucharest"
                 ]
               )
    end

    test "returns an error on JSON decode error", %{bypass: bypass, bypass_url: bypass_url} do
      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        conn
        |> Plug.Conn.resp(200, "{'malformed}")
      end)

      assert {:error, {:json_decode_data, _error}} =
               PTOBackendGoogleCalendar.list(
                 type: :pto,
                 config: [base_url: bypass_url, calendars: %{pto: "pto"}, time_zone: "Etc/UTC"]
               )
    end

    test "returns an error if the items field is missing", %{
      bypass: bypass,
      bypass_url: bypass_url
    } do
      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        conn
        |> Plug.Conn.resp(200, Jason.encode!(%{}))
      end)

      assert {:error, {:get_calendar_items, "The calendar response is missing the 'items' field"}} =
               PTOBackendGoogleCalendar.list(
                 type: :pto,
                 config: [base_url: bypass_url, calendars: %{pto: "pto"}, time_zone: "Etc/UTC"]
               )
    end

    test "returns an error if an item cannot be parsed", %{bypass: bypass, bypass_url: bypass_url} do
      Bypass.expect_once(bypass, "GET", "/pto/events", fn conn ->
        response =
          :google_events_response
          |> Factory.build()
          |> Map.put("items", [
            Factory.build(:google_event, %{
              "start" => %{"date" => "2022-01-53"}
            })
          ])

        conn
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:error, {:parse_filter_items, _error}} =
               PTOBackendGoogleCalendar.list(
                 type: :pto,
                 config: [base_url: bypass_url, calendars: %{pto: "pto"}, time_zone: "Etc/UTC"]
               )
    end
  end
end
