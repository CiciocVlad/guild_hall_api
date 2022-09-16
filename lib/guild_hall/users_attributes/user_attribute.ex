defmodule GuildHall.UsersAttributes.UserAttribute do
  use GuildHall.Schema
  import Ecto.Changeset

  alias GuildHall.Users.User
  alias GuildHall.Attributes.Attribute
  alias GuildHall.Projects.Project

  schema "user_attribute" do
    field :is_favorite, :boolean, default: false
    belongs_to :user, User
    belongs_to :attribute, Attribute
    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(user_attribute, attrs) do
    user_attribute
    |> cast(attrs, [:user_id, :attribute_id, :project_id, :is_favorite])
    |> validate_required([:user_id, :attribute_id])
    |> unique_constraint([:user_id, :attribute_id, :project_id], name: :unique_user_attribute)
  end
end
