defmodule GuildHall.Repo.Migrations.AddProjectsInfo do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :name
      add :title, :string
      add :category, :string
      add :description, :string
    end
  end
end
