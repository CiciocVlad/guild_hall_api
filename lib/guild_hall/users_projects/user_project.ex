defmodule GuildHall.UsersProjects.UserProject do
  use GuildHall.Schema
  import Ecto.Changeset

  alias GuildHall.Users.User
  alias GuildHall.Projects.Project
  alias GuildHall.Roles.Role

  schema "users_projects" do
    field :user_impact, :string
    field :end_date, :date
    field :start_date, :date
    belongs_to :user, User
    belongs_to :project, Project
    belongs_to :role, Role

    timestamps()
  end

  @doc false
  def changeset(user_project, attrs) do
    user_project
    |> cast(attrs, [:user_impact, :role_id, :start_date, :end_date, :user_id, :project_id])
    |> validate_required([:user_id, :project_id])
    |> unique_constraint([:user_id, :project_id], name: :unique_user_project)
  end
end
