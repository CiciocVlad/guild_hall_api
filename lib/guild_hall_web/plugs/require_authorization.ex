defmodule GuildHallWeb.Plugs.RequireAuthorization do
  import Plug.Conn
  alias GuildHallWeb.Helpers.JwtAuthToken
  alias GuildHallWeb.HttpUtils

  @auth_scheme "Bearer"

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:require_auth_header, :ok} <-
           {:require_auth_header, require_auth_header(conn)},
         {:require_bearer_auth, :ok} <-
           {:require_bearer_auth, require_bearer_auth(conn)},
         {:get_jwt_token, jwt_token} <- {:get_jwt_token, bearer_auth_creds(conn)},
         {:verify_jwt_token, {:ok, claims}} <-
           {:verify_jwt_token, JwtAuthToken.verify_and_validate(jwt_token)},
         {:get_user_id_from_claims, user_id} when not is_nil(user_id) and user_id != "" <-
           {:get_user_id_from_claims, Map.get(claims, "user_id")} do
      conn
      |> assign(:logged_user_id, user_id)
    else
      {requirement, {:error, reason}} ->
        conn
        |> forbidden({requirement, reason})

      {:get_user_id_from_claims, _value} ->
        conn
        |> forbidden({:get_user_id_from_claims, :empty_user_id})
    end
  end

  defp require_auth_header(conn) do
    if get_req_header(conn, "authorization") == [] do
      {:error, :missing_authorisation}
    else
      :ok
    end
  end

  defp require_bearer_auth(conn) do
    if bearer_auth?(conn) do
      :ok
    else
      {:error, :invalid_authorisation_scheme}
    end
  end

  defp bearer_auth?(conn) do
    conn
    |> get_authorization_header
    |> case do
      string when is_binary(string) ->
        String.starts_with?(string, @auth_scheme <> " ")

      _ ->
        false
    end
  end

  defp bearer_auth_creds(conn) do
    conn
    |> get_authorization_header
    |> String.slice((String.length(@auth_scheme) + 1)..-1)
  end

  defp get_authorization_header(conn) do
    conn
    |> get_req_header("authorization")
    |> List.first()
  end

  defp forbidden(conn, {_requirement, reason} = error) do
    message =
      case reason do
        :missing_authorisation ->
          "missing authorisation info"

        :invalid_authorisation_scheme ->
          "invalid authorisation scheme"

        :signature_error ->
          "invalid authorisation token"

        :empty_user_id ->
          "invalid authorisation token"

        _ ->
          nil
      end

    conn
    |> HttpUtils.unauthorized(message, error)
    |> halt()
  end
end
