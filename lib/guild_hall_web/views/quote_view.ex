defmodule GuildHallWeb.QuoteView do
  use GuildHallWeb, :view
  alias GuildHallWeb.QuoteView

  def render("index.json", %{quotes: quotes}), do: render_many(quotes, QuoteView, "quote.json")

  def render("show.json", %{quote: quote}), do: render_one(quote, QuoteView, "quote.json")

  def render("quote.json", %{quote: quote}),
    do:
      quote
      |> Map.from_struct()
      |> Map.take(~w[quote inserted_at]a)
end
