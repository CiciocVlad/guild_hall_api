defmodule GuildHall.BestOfQuotes.Quote do
  use GuildHall.Schema
  import Ecto.Changeset

  schema "best_of_quotes" do
    field :quote, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:quote, :user_id])
    |> validate_required([:quote, :user_id])
  end
end
