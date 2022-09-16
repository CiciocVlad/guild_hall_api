defmodule GuildHall.Repo.Migrations.CreateAttributes do
  use Ecto.Migration

  def change do
    create table(:attributes) do
      add :name, :string
      add :category_id, references(:categories, on_delete: :delete_all)

      timestamps()
    end
  end
end
