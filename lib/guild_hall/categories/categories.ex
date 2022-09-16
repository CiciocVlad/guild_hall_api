defmodule GuildHall.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias GuildHall.Repo

  alias GuildHall.Categories.Category

  @names %{
    soft_skill: "SoftSkill",
    hard_skill: "HardSkill",
    technology: "Technology",
    industry: "Industry",
    department: "Department"
  }

  @type symbolic_name :: :soft_skill | :hard_skill | :industry | :technology | :department

  @doc """
  Returns the string name for a named category.

  Raises when the input is not an atom or there is no named category with
  the given name.
  """
  @spec name!(name :: symbolic_name()) :: String.t()
  def name!(name) when is_atom(name) do
    Map.fetch!(@names, name)
  end

  def named() do
    Map.keys(@names)
  end

  def list_categories do
    from(
      c in Category,
      order_by: c.name
    )
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def get_category(id), do: Repo.get(Category, id)

  @doc """
  Returns the category struct for a named category.

  Raises when the input is not an atom or there is no named category with
  the given name.
  Returns `nil` when the category does not exist in the database.
  """
  @spec get_named_category(name :: symbolic_name()) :: map() | nil
  def get_named_category(name) when is_atom(name) do
    name = name!(name)

    from(
      c in Category,
      where: c.name == ^name
    )
    |> Repo.one()
  end

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end
end
