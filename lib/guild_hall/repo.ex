defmodule GuildHall.Repo do
  use Ecto.Repo,
    otp_app: :guild_hall,
    adapter: Ecto.Adapters.Postgres
end
