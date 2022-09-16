defmodule GuildHall.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :title, :string

      timestamps()
    end
  end
end
