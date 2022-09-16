defmodule GuildHall.Repo.Migrations.CategoriesUniqueAndSeed do
  use Ecto.Migration

  alias GuildHall.Categories.Category
  alias GuildHall.Categories

  def change do
    create(unique_index(:categories, ["lower(name)"], name: :unique_name))

    flush()

    execute(fn ->
      Categories.named()
      |> Enum.map(fn name ->
        repo().insert!(%Category{name: Categories.name!(name)}, on_conflict: :nothing)
      end)
    end)
  end
end
