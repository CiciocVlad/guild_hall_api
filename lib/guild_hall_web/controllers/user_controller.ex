defmodule GuildHallWeb.UserController do
  use GuildHallWeb, :controller

  alias GuildHall.Users
  alias GuildHall.Users.User
  alias GuildHall.Projects
  alias GuildHall.Projects.Project
  alias GuildHall.UsersProjects
  alias GuildHall.UsersProjects.UserProject
  alias GuildHall.Categories
  alias GuildHallWeb.HttpUtils
  alias GuildHallWeb.UserProjectView

  def index(conn, _params) do
    users = Users.list_users()
    conn |> render("index.json", users: users)
  end

  def list_users(conn, _params) do
    with users <- Users.list_users(),
         {:ok, off_today} <- GuildHall.PTODays.get_daily_status(Date.utc_today()) do
      conn
      |> render("list_users.json", users: users, off_today: Map.keys(off_today) |> MapSet.new())
    else
      {:error, error} ->
        conn
        |> HttpUtils.internal_error(nil, error)
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Users.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: user)
    else
      {:error, _} ->
        conn |> HttpUtils.bad_request("could not create user")
    end
  end

  def show(conn, %{"id" => id}) do
    case Users.get_user(id) do
      %User{} = user ->
        conn |> render("show.json", user: user)

      _ ->
        conn |> HttpUtils.not_found("could not find user")
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with {:get_user, %User{} = user} <- {:get_user, Users.get_user(id)},
         {:update_user, {:ok, %User{} = updated_user}} <-
           {:update_user, Users.update_user(user, user_params)} do
      conn |> render("show.json", user: updated_user)
    else
      {:get_user, _} ->
        conn |> HttpUtils.not_found("user not found")

      {:update_user, _} ->
        conn |> HttpUtils.bad_request("could not update user")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_user, %User{} = user} <- {:get_user, Users.get_user(id)},
         {:delete_user, {:ok, %User{}}} <- {:delete_user, user |> Users.delete_user()} do
      conn |> json(%{})
    else
      {:get_user, _} ->
        conn |> HttpUtils.not_found("user not found")

      {:delete_user, _} ->
        conn |> HttpUtils.bad_request("could not delete user")
    end
  end

  def get_project_users(conn, %{"project_id" => project_id}) do
    conn
    |> render("min_index.json", users: project_id |> UsersProjects.get_users_for_project_id())
  end

  def get_projects_of_user(conn, %{"user_id" => user_id}) do
    with {:get_user, %User{}} <- {:get_user, Users.get_user(user_id)},
         {:get_all_projects, all_projects} <- {:get_all_projects, Projects.list_projects()},
         {:get_projects_of_user, projects} <-
           {:get_projects_of_user, Users.get_projects_of_user(user_id)} do
      other_projects =
        all_projects
        |> MapSet.new()
        |> MapSet.difference(
          MapSet.new(projects |> Enum.map(fn %{project: p, user_project: _} -> p end))
        )
        |> MapSet.to_list()

      conn
      |> put_view(UserProjectView)
      |> render("index_projects.json", user_projects: projects, other_projects: other_projects)
    else
      {:get_user, _} -> conn |> HttpUtils.not_found("could not find user")
      {:get_projects, _} -> conn |> HttpUtils.not_found("could not find projects")
    end
  end

  def add_user_to_project(
        conn,
        %{"user_id" => user_id, "project_id" => project_id, "start_date" => _} = params
      ) do
    with {:get_user, %User{}} <- {:get_user, Users.get_user(user_id)},
         {:get_project, %Project{}} <- {:get_project, Projects.get_project(project_id)},
         {:ok, %UserProject{} = user_project} <- UsersProjects.create_user_project(params) do
      conn
      |> put_status(:created)
      |> put_view(UserProjectView)
      |> render("show.json", user_project: user_project)
    else
      {:get_user, _} ->
        conn |> HttpUtils.not_found("user not found")

      {:get_project, _} ->
        conn |> HttpUtils.not_found("project not found")

      {:ok, _} ->
        conn |> HttpUtils.bad_request("could not add user to project")
    end
  end

  def remove_user_from_project(conn, %{"user_id" => user_id, "project_id" => project_id}) do
    with {:get_user_project, %UserProject{} = user_project} <-
           {:get_user_project,
            UsersProjects.get_user_project_by_user_and_project_id(user_id, project_id)},
         {:remove_user_project, {:ok, _}} <-
           {:remove_user_project, UsersProjects.delete_user_project(user_project)} do
      conn |> json(%{})
    else
      {:get_user_project, _} ->
        conn |> HttpUtils.not_found("could not find user project")

      {:remove_user_project, _} ->
        conn |> HttpUtils.bad_request("could not delete user project")
    end
  end

  defp add_arrays(:users, value1, value2) do
    value1 ++ value2
  end

  defp add_arrays(_, value, _) do
    value
  end

  def get_data_for_projects(conn, %{"user_id" => user_id}) do
    with {:get_user, %User{}} <- {:get_user, Users.get_user(user_id)} do
      map = UsersProjects.get_colleagues(user_id) |> Enum.group_by(&(&1 |> hd))

      result =
        map
        |> Map.keys()
        |> Enum.map(fn key ->
          %{
            key =>
              map[key]
              |> Enum.map(fn [_, u, up] ->
                %{
                  users: if(u.id != user_id, do: [u.avatar], else: []),
                  role: if(is_nil(up.role), do: nil, else: up.role.title),
                  start_date: up.start_date,
                  end_date: up.end_date
                }
              end)
              |> Enum.reduce(fn acc, value -> acc |> Map.merge(value, &add_arrays/3) end)
          }
        end)

      conn
      |> render("index_data.json",
        data: result
      )
    else
      {:get_user, _} ->
        conn |> HttpUtils.bad_request("could not find user")
    end
  end

  def get_roles(conn, %{"user_id" => user_id}) do
    case Users.get_user(user_id) do
      %User{} ->
        roles = Users.get_roles(user_id)

        department =
          user_id
          |> Users.get_attributes(Categories.name!(:department))
          |> Enum.map(fn attr -> attr.name end)
          |> List.first()

        conn |> render("roles.json", roles: roles, department: department)

      _ ->
        conn |> HttpUtils.not_found("could not find user")
    end
  end

  def get_technologies(conn, %{"user_id" => user_id}) do
    case Users.get_user(user_id) do
      %User{} ->
        technologies = Users.get_attributes(user_id, Categories.name!(:technology))

        conn |> render("technologies.json", technologies: technologies)

      _ ->
        conn |> HttpUtils.not_found("could not find user")
    end
  end

  def get_off_today(conn, %{"email" => email}) do
    date = Date.utc_today()

    with {:ok, status} <- GuildHall.PTODays.get_daily_status(date),
         {:ok, item} <- Map.fetch(status, email) do
      conn
      |> json(%{
        start: item[:start_date],
        end: item[:end_date],
        off_today: true
      })
    else
      :error ->
        conn
        |> json(%{
          off_today: false
        })

      {:error, error} ->
        conn
        |> HttpUtils.internal_error(nil, error)
    end
  end

  def remaining_days_for_user(conn, %{"email" => email}) do
    year = Date.utc_today().year

    with {:get_user, %User{}} <-
           {:get_user, Users.get_by_email(email)},
         {:get_yearly_status, {:ok, status}} <-
           {:get_yearly_status, GuildHall.PTODays.get_yearly_status(email, year)} do
      conn
      |> json(%{
        "past_days" => GuildHall.PTODays.get_past_pto_for_user_email(email),
        "days_extra" => status[:extra],
        "days_off" => status[:nominal],
        "events" =>
          Enum.map(status[:details], fn item ->
            %{
              "start" => item[:start_date],
              "end" => item[:end_date],
              "number_of_days" => item[:working_days]
            }
          end),
        "add_days" =>
          status[:add_days]
          |> Enum.map(fn item ->
            %{
              "start" => item[:start_date],
              "end" => item[:end_date],
              "number_of_days" => item[:working_days]
            }
          end),
        "bonus_days" => status[:bonus_days],
        "remaining_days" => status[:remaining],
        "taken_days" => status[:taken]
      })
    else
      {:get_user, nil} ->
        conn
        |> HttpUtils.internal_error(nil, "current user not found")

      {:get_yearly_status, {:error, error}} ->
        conn
        |> HttpUtils.internal_error(nil, error)
    end
  end

  def remaining_days(conn, _params) do
    year = Date.utc_today().year

    with {:get_user, %User{email: email}} <-
           {:get_user, Users.get_user(conn.assigns.logged_user_id)},
         {:get_yearly_status, {:ok, status}} <-
           {:get_yearly_status, GuildHall.PTODays.get_yearly_status(email, year)} do
      conn
      |> json(%{
        "past_days" => GuildHall.PTODays.get_past_pto_for_user_email(email),
        "days_extra" => status[:extra],
        "days_off" => status[:nominal],
        "events" =>
          Enum.map(status[:details], fn item ->
            %{
              "start" => item[:start_date],
              "end" => item[:end_date],
              "number_of_days" => item[:working_days]
            }
          end),
        "add_days" =>
          status[:add_days]
          |> Enum.map(fn item ->
            %{
              "start" => item[:start_date],
              "end" => item[:end_date],
              "number_of_days" => item[:working_days]
            }
          end),
        "bonus_days" => status[:bonus_days],
        "remaining_days" => status[:remaining],
        "taken_days" => status[:taken]
      })
    else
      {:get_user, nil} ->
        conn
        |> HttpUtils.internal_error(nil, "current user not found")

      {:get_yearly_status, {:error, error}} ->
        conn
        |> HttpUtils.internal_error(nil, error)
    end
  end
end
