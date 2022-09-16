defmodule GuildHallWeb.AttributeView do
  use GuildHallWeb, :view
  alias GuildHallWeb.AttributeView

  def render("index.json", %{attributes: attributes}),
    do: render_many(attributes, AttributeView, "attribute.json")

  def render("index_category.json", %{attributes: attributes}),
    do: render_many(attributes, AttributeView, "attribute_with_category.json")

  def render("show.json", %{attribute: attribute}),
    do: render_one(attribute, AttributeView, "attribute.json")

  def render("show_category.json", %{attribute: attribute}),
    do: render_one(attribute, AttributeView, "attribute_with_category.json")

  def render("attribute.json", %{attribute: attribute}),
    do: attribute |> Map.from_struct() |> Map.take(~w/id name/a)

  def render("attribute_with_category.json", %{attribute: attribute}), do: attribute
end
