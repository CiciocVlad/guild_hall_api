defmodule GuildHall.Categories.Category do
  use GuildHall.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name], name: :unique_name)
  end
end
