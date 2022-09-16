defmodule GuildHallWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GuildHallWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import GuildHallWeb.ConnCase

      alias GuildHall.Factory
      alias GuildHall.Repo

      alias GuildHallWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint GuildHallWeb.Endpoint

      defp map_with_string_keys(map) do
        Enum.into(map, %{}, fn {k, v} -> {to_string(k), v} end)
      end

      defp add_authorisation(conn, user) do
        conn
        |> put_req_header(
          "authorization",
          "Bearer " <>
            GuildHallWeb.Helpers.JwtAuthToken.generate_jwt(claims: %{"user_id" => user.id})
        )
      end

      defp create_and_authorise_user(%{conn: conn}) do
        user = Factory.insert(:user)

        {:ok, user: user, conn: add_authorisation(conn, user)}
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(GuildHall.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(GuildHall.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  defmacro test_returns_401(name, fun) do
    quote do
      test "#{unquote(name)} returns 401", %{conn: conn} do
        conn = unquote(fun).(conn)

        assert json_response(conn, 401) == %{"errorMsg" => "missing authorisation info"}
      end
    end
  end

  defmacro test_returns_404_with_random_id(error_message, fun) do
    for {case_name, value} <- [
          {"valid UUID", Ecto.UUID.generate()},
          {"invalid UUID", "invalid UUID"}
        ] do
      quote do
        test "returns 404 with random ID (#{unquote(case_name)})", %{
          conn: conn
        } do
          conn = unquote(fun).(conn, unquote(value))

          assert json_response(conn, 404) == %{"errorMsg" => unquote(error_message)}
        end
      end
    end
  end
end
