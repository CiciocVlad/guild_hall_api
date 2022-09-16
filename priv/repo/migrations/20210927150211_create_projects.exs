defmodule GuildHall.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :start_date, :date
      add :end_date, :date

      timestamps()
    end
  end
end
