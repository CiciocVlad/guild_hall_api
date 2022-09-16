defmodule GuildHall.BestOfQuotes do
  @moduledoc """
  The BestOfQuotes context.
  """

  import Ecto.Query, warn: false
  alias GuildHall.Repo

  alias GuildHall.BestOfQuotes.Quote

  def list_quotes do
    Repo.all(Quote)
  end

  def get_quote!(id), do: Repo.get!(Quote, id)

  def create_quote(attrs \\ %{}) do
    %Quote{}
    |> Quote.changeset(attrs)
    |> Repo.insert()
  end

  def update_quote(%Quote{} = quote, attrs) do
    quote
    |> Quote.changeset(attrs)
    |> Repo.update()
  end

  def delete_quote(%Quote{} = quote) do
    Repo.delete(quote)
  end

  def change_quote(%Quote{} = quote, attrs \\ %{}) do
    Quote.changeset(quote, attrs)
  end
end
