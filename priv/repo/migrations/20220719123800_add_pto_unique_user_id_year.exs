defmodule GuildHall.Repo.Migrations.AddPTOUniqueUserIdYear do
  use Ecto.Migration

  def change do
    create(unique_index(:pto, [:user_id, :year], name: :unique_user_year))
  end
end
