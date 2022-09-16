defmodule GuildHall.Roles.Role do
  use GuildHall.Schema
  import Ecto.Changeset

  schema "roles" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
