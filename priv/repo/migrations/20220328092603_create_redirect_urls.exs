defmodule GuildHall.Repo.Migrations.CreateRedirectUrls do
  use Ecto.Migration

  def change do
    create table(:redirect_urls) do
      add :mapping, :string
      add :destination, :string
      add :expires_at, :utc_datetime

      timestamps()
    end

    create(unique_index(:redirect_urls, [:mapping], name: :unique_mapping))
  end
end
