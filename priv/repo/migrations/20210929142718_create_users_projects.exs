defmodule GuildHall.Repo.Migrations.CreateUsersProjects do
  use Ecto.Migration

  def change do
    create table(:users_projects) do
      add :role_id, :uuid
      add :start_date, :date
      add :end_date, :date
      add :user_id, references(:users, on_delete: :delete_all)
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

    create(unique_index(:users_projects, [:user_id, :project_id], name: :unique_user_project))
  end
end
