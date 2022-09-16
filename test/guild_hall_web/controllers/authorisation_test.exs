defmodule GuildHall.Controllers.AuthorisationTest do
  use GuildHallWeb.ConnCase

  alias GuildHallWeb.Helpers.JwtAuthToken

  alias ExUnit.CaptureLog

  test "user_path(:get_off_today) returns 401 without authentication", %{conn: conn} do
    log =
      CaptureLog.capture_log(fn ->
        conn =
          conn
          |> post(Routes.user_path(conn, :get_off_today, %{email: "some email"}))

        assert json_response(conn, 401) == %{"errorMsg" => "missing authorisation info"}
      end)

    assert log =~
             "Unauthorised: missing authorisation info ({:require_auth_header, :missing_authorisation})"
  end

  test "user_path(:get_off_today) returns 401 with a different auth scheme", %{conn: conn} do
    log =
      CaptureLog.capture_log(fn ->
        conn =
          conn
          |> put_req_header(
            "authorization",
            "Bear " <> JwtAuthToken.generate_jwt(claims: %{"user_id" => "user_id"})
          )
          |> post(Routes.user_path(conn, :get_off_today, %{email: "some email"}))

        assert json_response(conn, 401) == %{"errorMsg" => "invalid authorisation scheme"}
      end)

    assert log =~
             "Unauthorised: invalid authorisation scheme ({:require_bearer_auth, :invalid_authorisation_scheme})"
  end

  test "user_path(:get_off_today) returns 401 with an invalid token", %{conn: conn} do
    log =
      CaptureLog.capture_log(fn ->
        conn =
          conn
          |> put_req_header("authorization", "Bearer invalid-token")
          |> post(Routes.user_path(conn, :get_off_today, %{email: "some email"}))

        assert json_response(conn, 401) == %{"errorMsg" => "invalid authorisation token"}
      end)

    assert log =~
             "Unauthorised: invalid authorisation token ({:verify_jwt_token, :signature_error})"
  end

  test "user_path(:get_off_today) returns 401 with a valid token that has invalid claims", %{
    conn: conn
  } do
    log =
      CaptureLog.capture_log(fn ->
        conn =
          conn
          |> put_req_header(
            "authorization",
            "Bearer " <> JwtAuthToken.generate_jwt(claims: %{"user_id" => ""})
          )
          |> post(Routes.user_path(conn, :get_off_today, %{email: "some email"}))

        assert json_response(conn, 401) == %{"errorMsg" => "invalid authorisation token"}
      end)

    assert log =~
             "Unauthorised: invalid authorisation token ({:get_user_id_from_claims, :empty_user_id})"
  end
end
