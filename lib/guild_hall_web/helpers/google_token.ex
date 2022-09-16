defmodule GuildHallWeb.GoogleToken do
  @issuer "accounts.google.com"

  def request(id_token) do
    url = "https://oauth2.googleapis.com/tokeninfo?id_token=#{id_token}"
    HTTPoison.get(url)
  end

  defp is_exp_valid?(exp) do
    exp_time = Integer.parse(exp) |> elem(0)
    exp_time > DateTime.utc_now() |> DateTime.to_unix()
  end

  defp get_client_id(), do: System.fetch_env!("GUILD_HALL_GOOGLE_CLIENT_ID")

  def validate(response) do
    with {:request_success, {:ok, %HTTPoison.Response{body: body}}} <-
           {:request_success, response},
         {:decoded_body, {:ok, decoded_body}} <- {:decoded_body, Jason.decode(body)},
         {:valid_aud, true} <- {:valid_aud, decoded_body["aud"] == get_client_id()},
         {:valid_exp, true} <- {:valid_exp, is_exp_valid?(decoded_body["exp"])},
         {:valid_iss, true} <- {:valid_iss, decoded_body["iss"] == @issuer} do
      {:ok, decoded_body}
    else
      error_result -> {:error, error_result}
    end
  end
end
