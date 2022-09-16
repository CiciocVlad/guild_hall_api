defmodule GuildHallWeb.AuthView do
  use GuildHallWeb, :view
  alias GuildHallWeb.UserView

  def render("show.json", %{token: token, user: user}),
    do: %{
      token: token,
      user: UserView.render("show_minimum.json", %{user: user})
    }
end
