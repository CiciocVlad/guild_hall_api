defmodule GuildHall.Attributes.Attribute do
  use GuildHall.Schema
  import Ecto.Changeset

  alias GuildHall.Categories.Category

  schema "attributes" do
    field :name, :string
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(attribute, attrs) do
    attribute
    |> cast(attrs, [:name, :category_id])
    |> validate_required([:name, :category_id])
    |> unique_constraint([:name], name: :unique_name_in_category)
  end
end
