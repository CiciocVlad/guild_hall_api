defmodule GuildHallWeb.ArticleView do
  use GuildHallWeb, :view
  alias GuildHallWeb.ArticleView

  def render("index.json", %{articles: articles}),
    do: render_many(articles, ArticleView, "article.json")

  def render("show.json", %{article: article}),
    do: render_one(article, ArticleView, "article.json")

  def render("article.json", %{article: article}),
    do:
      article
      |> Map.from_struct()
      |> Map.take(~w[link inserted_at]a)
end
