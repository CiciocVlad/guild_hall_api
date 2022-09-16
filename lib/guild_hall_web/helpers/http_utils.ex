defmodule GuildHallWeb.HttpUtils do
  import Plug.Conn
  import Phoenix.Controller
  require Logger

  defp log(prefix, message, raw_error) do
    message_to_log = String.trim("#{message} (#{inspect(raw_error)})")

    if message_to_log == "()" do
      Logger.warn(prefix)
    else
      Logger.warn("#{prefix}: #{message_to_log}")
    end
  end

  def bad_request(conn, message \\ nil, raw_error \\ nil) do
    log("Bad request", message, raw_error)

    conn
    |> put_status(:bad_request)
    |> json(%{errorMsg: message || "bad request"})
  end

  def not_found(conn, message \\ nil, raw_error \\ nil) do
    log("Not found", message, raw_error)

    conn
    |> put_status(:not_found)
    |> json(%{errorMsg: message || "not found"})
  end

  def unauthorized(conn, message \\ nil, raw_error \\ nil) do
    log("Unauthorised", message, raw_error)

    conn
    |> put_status(:unauthorized)
    |> json(%{errorMsg: message || "unauthorised"})
  end

  def internal_error(conn, message \\ nil, raw_error \\ nil) do
    log("Internal server error", message, raw_error)

    conn
    |> put_status(500)
    |> json(%{errorMsg: message || "internal server error"})
  end
end
