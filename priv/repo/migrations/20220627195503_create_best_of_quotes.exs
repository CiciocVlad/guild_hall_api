defmodule GuildHall.Repo.Migrations.CreateBestOfQuotes do
  use Ecto.Migration

  def change do
    create table(:best_of_quotes) do
      add :quote, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
