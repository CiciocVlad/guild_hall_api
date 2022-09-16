defmodule GuildHall.Articles.Article do
  use GuildHall.Schema
  import Ecto.Changeset

  schema "articles" do
    field :link, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:link, :user_id])
    |> validate_required([:link, :user_id])
  end
end
