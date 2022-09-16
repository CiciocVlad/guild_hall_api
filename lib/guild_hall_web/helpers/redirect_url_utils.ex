defmodule GuildHallWeb.RedirectUrlUtils do
  def random_string(string_length) do
    :crypto.strong_rand_bytes(string_length)
    |> Base.url_encode64()
    |> binary_part(0, string_length)
  end
end
