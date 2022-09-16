defmodule GuildHallWeb.ArticleController do
  use GuildHallWeb, :controller

  alias GuildHall.Articles
  alias GuildHall.Articles.Article
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    articles = Articles.list_articles()
    conn |> render("index.json", articles: articles)
  end

  def create(conn, %{"article" => article_params}) do
    with {:ok, %Article{} = article} <- Articles.create_article(article_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.article_path(conn, :show, article))
      |> render("show.json", article: article)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("could not create article")
    end
  end

  def show(conn, %{"id" => id}) do
    article = Articles.get_article!(id)
    conn |> render("show.json", article: article)
  end
end
