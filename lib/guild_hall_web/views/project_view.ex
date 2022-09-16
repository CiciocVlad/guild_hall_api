defmodule GuildHallWeb.ProjectView do
  use GuildHallWeb, :view
  alias GuildHallWeb.ProjectView

  def render("index.json", %{projects: projects}),
    do: render_many(projects, ProjectView, "project.json")

  def render("show.json", %{project: project}),
    do: render_one(project, ProjectView, "project.json")

  def render("project.json", %{project: project}) do
    project
    |> Map.from_struct()
    |> Map.take(~w/id title category description start_date end_date/a)
  end
end
