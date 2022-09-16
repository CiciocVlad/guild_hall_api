defmodule GuildHall.UsersAttributes do
  @moduledoc """
  The Usersattributes context.
  """

  import Ecto.Query, warn: false
  alias GuildHall.Repo
  alias GuildHall.UsersAttributes.UserAttribute
  alias GuildHall.Attributes.Attribute

  def list_user_attribute do
    Repo.all(UserAttribute)
  end

  def get_user_attribute!(id), do: Repo.get!(UserAttribute, id)

  def create_user_attribute(attrs \\ %{}) do
    %UserAttribute{}
    |> UserAttribute.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_attribute(%UserAttribute{} = user_attribute, attrs) do
    user_attribute
    |> UserAttribute.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_attribute(%UserAttribute{} = user_attribute) do
    Repo.delete(user_attribute)
  end

  def change_user_attribute(%UserAttribute{} = user_attribute, attrs \\ %{}) do
    UserAttribute.changeset(user_attribute, attrs)
  end

  def get_attributes_for_user_id(user_id) do
    from(
      s in Attribute,
      join: us in UserAttribute,
      on: us.user_id == ^user_id and us.attribute_id == s.id,
      select: %{id: us.id, name: s.name, is_favorite: us.is_favorite, category_id: s.category_id}
    )
    |> Repo.all()
  end

  def get_attribute_for_user_id(user_id, attribute_id) do
    from(
      us in UserAttribute,
      where: us.attribute_id == ^attribute_id and us.user_id == ^user_id
    )
    |> Repo.one()
  end
end
