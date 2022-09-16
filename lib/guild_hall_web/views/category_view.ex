defmodule GuildHallWeb.CategoryView do
  use GuildHallWeb, :view
  alias GuildHallWeb.CategoryView

  def render("index.json", %{categories: categories}),
    do: render_many(categories, CategoryView, "category.json")

  def render("show.json", %{category: category}),
    do: render_one(category, CategoryView, "category.json")

  def render("category.json", %{category: category}),
    do: category |> Map.from_struct() |> Map.take(~w/id name/a)
end
