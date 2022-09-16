defmodule GuildHall.PTODays.PTO do
  use GuildHall.Schema
  import Ecto.Changeset

  schema "pto" do
    field :days, :integer
    field :year, :integer
    belongs_to :user, GuildHall.Users.User

    timestamps()
  end

  @doc """
  Creates a changeset for the create operation.
  """
  def changeset_for_create(pto, attrs) do
    pto
    |> cast(attrs, [:year, :days, :user_id])
    |> validate_required([:year, :days, :user_id])
    |> unique_constraint([:user_year], name: :unique_user_year)
  end

  @doc """
  Creates a changeset for the update operation (ignores the `user_id` field).
  """
  def changeset_for_update(pto, attrs) do
    pto
    |> cast(attrs, [:year, :days])
    |> validate_required([:year, :days])
    |> unique_constraint([:user_year], name: :unique_user_year)
  end
end
