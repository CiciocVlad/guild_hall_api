defmodule GuildHall.UsersProjects do
  import Ecto.Query, warn: false
  alias GuildHall.Repo
  alias GuildHall.UsersProjects.UserProject
  alias GuildHall.Projects.Project
  alias GuildHall.Users.User

  def list_users_projects do
    Repo.all(UserProject)
  end

  def get_user_project!(id), do: Repo.get!(UserProject, id)

  def get_user_project(id), do: Repo.get(UserProject, id)

  def create_user_project(attrs \\ %{}) do
    %UserProject{}
    |> UserProject.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_project(%UserProject{} = user_project, attrs) do
    user_project
    |> UserProject.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_project(%UserProject{} = user_project) do
    Repo.delete(user_project)
  end

  def change_user_project(%UserProject{} = user_project, attrs \\ %{}) do
    UserProject.changeset(user_project, attrs)
  end

  def get_user_projects_for_user_id(user_id) do
    from(
      p in Project,
      join: up in UserProject,
      on: up.user_id == ^user_id and up.project_id == p.id
    )
    |> Repo.all()
  end

  def get_users_for_project_id(project_id) do
    from(
      u in User,
      join: up in UserProject,
      on: up.project_id == ^project_id and up.user_id == u.id,
      select: [up.role_id, up.end_date, u.avatar]
    )
    |> Repo.all()
  end

  def get_colleagues(user_id) do
    from(
      up in UserProject,
      join: p in Project,
      on: up.project_id == p.id,
      join: up_u in UserProject,
      on: up.project_id == up_u.project_id,
      preload: [:role],
      join: u in User,
      on: up_u.user_id == u.id,
      where: up.user_id == ^user_id,
      order_by: p.id,
      select: [p, u, up]
    )
    |> Repo.all()
  end

  def get_user_project_by_user_and_project_id(user_id, project_id) do
    from(u in UserProject, where: u.user_id == ^user_id and u.project_id == ^project_id)
    |> Repo.one()
  end
end
