defmodule GuildHall.RedirectUrls.RedirectUrl do
  use GuildHall.Schema
  import Ecto.Changeset
  alias GuildHall.Users.User

  schema "redirect_urls" do
    field :expires_at, :utc_datetime
    field :mapping, :string
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(redirect_url, attrs) do
    redirect_url
    |> cast(attrs, [:mapping, :user_id, :expires_at])
    |> validate_required([:user_id])
    |> unique_constraint([:mapping], name: :unique_mapping)
  end
end
