defmodule GuildHallWeb.RoleController do
  use GuildHallWeb, :controller

  alias GuildHall.Roles
  alias GuildHall.Roles.Role
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    roles = Roles.list_roles()
    conn |> render("index.json", roles: roles)
  end

  def create(conn, %{"role" => role_params}) do
    with {:ok, %Role{} = role} <- Roles.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.role_path(conn, :show, role))
      |> render("show.json", role: role)
    else
      {:error, _} ->
        conn |> HttpUtils.bad_request("could not create role")
    end
  end

  def show(conn, %{"id" => id}) do
    role = Roles.get_role!(id)
    conn |> render("show.json", role: role)
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    with {:get_role, %Role{} = role} <- {:get_role, Roles.get_role(id)},
         {:update_role, {:ok, %Role{} = updated_role}} <-
           {:update_role, Roles.update_role(role, role_params)} do
      conn |> render("show.json", role: updated_role)
    else
      {:get_role, _} ->
        HttpUtils.not_found("role not found")

      {:update_role, _} ->
        HttpUtils.bad_request("could not update role")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_role, %Role{} = role} <- {:get_role, Roles.get_role(id)},
         {:delete_role, {:ok, %Role{}}} <- {:delete_role, Roles.delete_role(role)} do
      conn |> json(%{})
    else
      {:get_role, _} ->
        conn |> HttpUtils.not_found("role not found")

      {:delete_role, _} ->
        conn |> HttpUtils.bad_request("could not delete role")
    end
  end
end
