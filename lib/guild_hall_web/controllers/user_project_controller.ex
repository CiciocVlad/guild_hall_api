defmodule GuildHallWeb.UserProjectController do
  use GuildHallWeb, :controller

  alias GuildHall.UsersProjects
  alias GuildHall.UsersProjects.UserProject
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    users_projects = UsersProjects.list_users_projects()
    conn |> render("index.json", users_projects: users_projects)
  end

  def create(conn, %{"user_project" => user_project_params}) do
    with {:ok, %UserProject{} = user_project} <-
           UsersProjects.create_user_project(user_project_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_project_path(conn, :show, user_project))
      |> render("show.json", user_project: user_project)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("could not add project to user")
    end
  end

  def show(conn, %{"id" => id}) do
    user_project = UsersProjects.get_user_project!(id)
    conn |> render("show.json", user_project: user_project)
  end

  def delete(conn, %{"id" => id}) do
    with {:get_user_project, %UserProject{} = user_project} <-
           {:get_user_project, UsersProjects.get_user_project(id)},
         {:delete_user_project, {:ok, %UserProject{}}} <-
           {:delete_user_project, UsersProjects.delete_user_project(user_project)} do
      conn |> json(%{})
    else
      {:get_user_project, _} -> conn |> HttpUtils.not_found("link not found")
      {:delete_user_project, _} -> conn |> HttpUtils.bad_request("could not delete link")
    end
  end
end
