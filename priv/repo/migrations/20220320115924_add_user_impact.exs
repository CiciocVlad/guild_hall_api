defmodule GuildHall.Repo.Migrations.AddUserImpact do
  use Ecto.Migration

  def change do
    alter table(:users_projects) do
      add :user_impact, :string
    end
  end
end
