defmodule GuildHall.Repo.Migrations.AddFavoriteField do
  use Ecto.Migration

  def change do
    alter table(:user_attribute) do
      add :is_favorite, :boolean, default: false
    end
  end
end
