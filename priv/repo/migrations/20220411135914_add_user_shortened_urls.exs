defmodule GuildHall.Repo.Migrations.AddUserShortenedUrls do
  use Ecto.Migration

  def change do
    alter table(:redirect_urls) do
      remove :destination
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
