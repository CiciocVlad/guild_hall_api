defmodule GuildHallWeb.ProjectController do
  use GuildHallWeb, :controller

  alias GuildHall.Projects
  alias GuildHall.Projects.Project
  alias GuildHallWeb.HttpUtils
  alias GuildHall.UsersProjects
  alias GuildHall.UsersProjects.UserProject
  alias GuildHallWeb.UserProjectView

  def index(conn, _params) do
    projects = Projects.list_projects()
    conn |> render("index.json", projects: projects)
  end

  def create(conn, %{"project" => project_params}) do
    with {:ok, %Project{} = project} <- Projects.create_project(project_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.project_path(conn, :show, project))
      |> render("show.json", project: project)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("Could not create project")
    end
  end

  def show(conn, %{"id" => id}) do
    project = Projects.get_project!(id)
    conn |> render("show.json", project: project)
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    with {:get_project, %Project{} = project} <- {:get_project, Projects.get_project(id)},
         {:update_project, {:ok, %Project{} = updated_project}} <-
           {:update_project, Projects.update_project(project, project_params)} do
      conn |> render("show.json", project: updated_project)
    else
      {:get_project, _} -> conn |> HttpUtils.not_found("Project not found")
      {:update_project, _} -> conn |> HttpUtils.bad_request("Project could not be updated")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_project, %Project{} = project} <- {:get_project, Projects.get_project(id)},
         {:delete_project, {:ok, %Project{}}} <-
           {:delete_project, Projects.delete_project(project)} do
      conn |> json(%{})
    else
      {:get_project, _} -> conn |> HttpUtils.not_found("Project not found")
      {:delete_project, _} -> conn |> HttpUtils.bad_request("Project could not be deleted")
    end
  end

  def get_user_projects(conn, %{"user_id" => user_id}) do
    conn
    |> render("index.json", projects: user_id |> UsersProjects.get_user_projects_for_user_id())
  end

  def add_user_impact(conn, %{
        "project_id" => project_id,
        "user_id" => user_id,
        "user_impact" => user_impact
      }) do
    with {:get_user_project, %UserProject{} = user_project} <-
           {:get_user_project,
            UsersProjects.get_user_project_by_user_and_project_id(user_id, project_id)},
         {:update_user_project, {:ok, %UserProject{} = updated_user_project}} <-
           {:update_user_project,
            UsersProjects.update_user_project(user_project, %{user_impact: user_impact})} do
      conn |> put_view(UserProjectView) |> render("show.json", user_project: updated_user_project)
    else
      {:get_user_project, _} ->
        conn |> HttpUtils.not_found("given user does not work on this project")

      {:update_user_project, _} ->
        conn |> HttpUtils.bad_request("could not update user project")
    end
  end
end
