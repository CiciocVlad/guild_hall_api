defmodule GuildHallWeb.UserProjectView do
  use GuildHallWeb, :view
  alias GuildHallWeb.UserProjectView

  def render("index.json", %{users_projects: users_projects}),
    do: render_many(users_projects, UserProjectView, "user_project.json")

  def render("show.json", %{user_project: user_project}),
    do: render_one(user_project, UserProjectView, "user_project.json")

  def render("user_project.json", %{user_project: user_project}),
    do:
      user_project
      |> Map.from_struct()
      |> Map.drop(~w/__meta__ inserted_at updated_at user project role/a)

  def render("index_projects.json", %{
        user_projects: user_projects,
        other_projects: other_projects
      }),
      do: %{
        user_projects:
          user_projects
          |> Enum.map(fn user_project ->
            render("user_projects.json", user_project: user_project)
          end),
        other_projects:
          other_projects
          |> Enum.map(fn other_project ->
            render("other_project.json", other_project: other_project)
          end)
      }

  def render("user_projects.json", %{
        user_project: %{project: project, user_project: user_project}
      }),
      do: %{
        project:
          project
          |> Map.from_struct()
          |> Map.take(~w[id title category description start_date end_date]a),
        user_project: user_project |> Map.from_struct() |> Map.take(~w[id user_id project_id]a)
      }

  def render("other_project.json", %{other_project: other_project}),
    do:
      other_project
      |> Map.from_struct()
      |> Map.take(~w[id title category description start_date end_date]a)
end
