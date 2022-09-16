defmodule GuildHall.Repo.Migrations.CreatePto do
  use Ecto.Migration

  def change do
    create table(:pto) do
      add :year, :integer
      add :days, :integer
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
