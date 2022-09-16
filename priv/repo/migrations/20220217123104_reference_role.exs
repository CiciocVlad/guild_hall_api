defmodule GuildHall.Repo.Migrations.ReferenceRole do
  use Ecto.Migration

  def change do
    alter table(:users_projects) do
      remove :role_id
      add :role_id, references(:roles, on_delete: :delete_all)
    end
  end
end
