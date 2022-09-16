defmodule GuildHallWeb.UserAttributeView do
  use GuildHallWeb, :view
  alias GuildHallWeb.UserAttributeView

  def render("index.json", %{users_attributes: users_attributes}),
    do: render_many(users_attributes, UserAttributeView, "user_attribute.json")

  def render("show.json", %{user_attribute: user_attribute}),
    do: render_one(user_attribute, UserAttributeView, "user_attribute.json")

  def render("user_attribute.json", %{user_attribute: user_attribute}),
    do:
      user_attribute
      |> Map.from_struct()
      |> Map.take(~w[id user_id attribute_id]a)
end
