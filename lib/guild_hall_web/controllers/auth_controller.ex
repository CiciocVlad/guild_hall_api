defmodule GuildHallWeb.AuthController do
  use GuildHallWeb, :controller
  alias GuildHallWeb.HttpUtils
  alias GuildHall.Accounts
  alias GuildHall.Users.User
  alias GuildHallWeb.Helpers.JwtAuthToken
  import GuildHallWeb.GoogleToken

  def authenticate_with_token(conn, %{"id_token" => id_token}) do
    with {:valid_token, {:ok, body}} <-
           {:valid_token, request(id_token) |> validate},
         {:user_sync, {:ok, %User{} = user}} <-
           {:user_sync, Accounts.sync_user(body)} do
      conn
      |> render("show.json", %{
        token: JwtAuthToken.generate_jwt(claims: %{user_id: user.id}),
        user: user
      })
    else
      error -> conn |> HttpUtils.bad_request("invalid token", error)
    end
  end
end
