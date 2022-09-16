defmodule GuildHall.Repo.Migrations.ChangeExpiresAtType do
  use Ecto.Migration

  def change do
    alter table(:redirect_urls) do
      remove :expires_at
      add :expires_at, :utc_datetime
    end
  end
end
