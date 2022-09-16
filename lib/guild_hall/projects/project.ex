defmodule GuildHall.Projects.Project do
  use GuildHall.Schema
  import Ecto.Changeset

  alias GuildHall.Users.User

  schema "projects" do
    field :end_date, :date
    field :title, :string
    field :category, :string
    field :description, :string
    field :start_date, :date
    many_to_many :users, User, join_through: "users_projects", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :category, :description, :start_date, :end_date])
    |> validate_required([:title, :category, :description])
  end
end
