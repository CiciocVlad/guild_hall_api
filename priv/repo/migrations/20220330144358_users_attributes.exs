defmodule GuildHall.Repo.Migrations.UsersAttributes do
  use Ecto.Migration

  def change do
    create table(:user_attribute) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :attribute_id, references(:attributes, on_delete: :delete_all)
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

    execute(
      "create unique index unique_user_attribute on user_attribute(user_id, attribute_id) where (project_id is null)"
    )

    execute(
      "create unique index unique_user_attribute_project on user_attribute(user_id, attribute_id, project_id)"
    )
  end
end
