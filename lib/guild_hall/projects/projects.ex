defmodule GuildHall.Projects do
  import Ecto.Query, warn: false
  alias GuildHall.Repo
  alias GuildHall.Projects.Project

  def list_projects do
    from(
      project in Project,
      order_by: project.title
    )
    |> Repo.all()
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_project(id), do: Repo.get(Project, id)

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end
end
