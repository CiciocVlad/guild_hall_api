defmodule GuildHallWeb.QuoteController do
  use GuildHallWeb, :controller

  alias GuildHall.BestOfQuotes
  alias GuildHall.BestOfQuotes.Quote
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    quotes = BestOfQuotes.list_quotes()
    conn |> render("index.json", quotes: quotes)
  end

  def create(conn, %{"quote" => quote_params}) do
    with {:ok, %Quote{} = quote} <- BestOfQuotes.create_quote(quote_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.quote_path(conn, :show, quote))
      |> render("show.json", quote: quote)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("could not create quote")
    end
  end

  def show(conn, %{"id" => id}) do
    quote = BestOfQuotes.get_quote!(id)
    conn |> render("show.json", quote: quote)
  end
end
