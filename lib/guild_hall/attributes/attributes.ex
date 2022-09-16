defmodule GuildHall.Attributes do
  @moduledoc """
  The Attributes context.
  """

  import Ecto.Query, warn: false
  alias GuildHall.Repo

  alias GuildHall.Attributes.Attribute
  alias GuildHall.Categories.Category
  alias GuildHall.Projects.Project
  alias GuildHall.UsersAttributes.UserAttribute
  alias GuildHall.UsersProjects.UserProject

  def list_attributes do
    from(a in Attribute,
      order_by: a.name
    )
    |> Repo.all()
  end

  def get_attribute!(id), do: Repo.get!(Attribute, id)

  def get_attribute(id), do: Repo.get(Attribute, id)

  def create_attribute(attrs \\ %{}) do
    %Attribute{}
    |> Attribute.changeset(attrs)
    |> Repo.insert()
  end

  def update_attribute(%Attribute{} = attribute, attrs) do
    attribute
    |> Attribute.changeset(attrs)
    |> Repo.update()
  end

  def delete_attribute(%Attribute{} = attribute) do
    Repo.delete(attribute)
  end

  def list_attributes_with_category() do
    from(
      a in Attribute,
      join: c in assoc(a, :category),
      select: %{id: a.id, name: a.name, category_name: c.name},
      order_by: a.name
    )
    |> Repo.all()
  end

  def list_attributes_for_user(user_id) do
    from(
      a in Attribute,
      join: ua in UserAttribute,
      on: a.id == ua.attribute_id and ^user_id == ua.user_id
    )
    |> Repo.all
  end

  def get_attributes_of_user_on_project(user) do
    query =
      from(
        ua in UserAttribute,
        where: ^user.id == ua.user_id
      )

    from(
      p in Project,
      join: up in UserProject,
      on: p.id == up.project_id and ^user.id == up.user_id,
      left_join: ua in subquery(query),
      on: ua.project_id == p.id,
      left_join: a in Attribute,
      on: a.id == ua.attribute_id,
      left_join: c in Category,
      on: a.category_id == c.id,
      select: %{
        %{
          title: p.title,
          description: p.description,
          category: p.category,
          user_impact: up.user_impact
        } => [%{id: a.id, name: a.name, category: c.name}]
      }
    )
    |> Repo.all()
  end

  def get_attribute_with_category(id) do
    from(
      a in Attribute,
      join: c in assoc(a, :category),
      where: a.id == ^id,
      select: %{id: a.id, name: a.name, category_name: c.name}
    )
    |> Repo.one()
  end

  def get_filters do
    from(
      a in Attribute,
      join: c in assoc(a, :category),
      where: c.name == "Department" or c.name == "Technology",
      select: %{id: a.id, name: a.name, category: c.name, category_id: c.id}
    )
    |> Repo.all()
  end
end
