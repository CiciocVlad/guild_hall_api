defmodule GuildHallWeb.RedirectUrlView do
  use GuildHallWeb, :view
  alias GuildHallWeb.RedirectUrlView

  def render("index.json", %{redirect_urls: redirect_urls}),
    do: render_many(redirect_urls, RedirectUrlView, "redirect_url.json")

  def render("show.json", %{redirect_url: redirect_url}),
    do: render_one(redirect_url, RedirectUrlView, "redirect_url.json")

  def render("redirect_url.json", %{redirect_url: redirect_url}),
    do:
      redirect_url
      |> Map.from_struct()
      |> Map.drop(~w/__meta__ inserted_at updated_at user user_id/a)
end
