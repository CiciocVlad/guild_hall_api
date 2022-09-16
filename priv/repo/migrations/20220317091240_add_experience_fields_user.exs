defmodule GuildHall.Repo.Migrations.AddExperienceFieldsUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :years_of_experience, :string
      add :number_of_industries, :string
      add :number_of_projects, :string
    end
  end
end
