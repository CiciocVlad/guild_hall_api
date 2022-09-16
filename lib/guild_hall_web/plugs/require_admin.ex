defmodule GuildHallWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import GuildHallWeb.HttpUtils
  alias GuildHall.Users
  alias GuildHall.Users.User

  def init(opts), do: opts

  def call(conn, _opts) do
    case Users.get_user!(conn.assigns.logged_user_id) do
      %User{is_admin: true} -> conn
      _ -> conn |> unauthorized("User is not authorized to do the request.") |> halt()
    end
  end
end
