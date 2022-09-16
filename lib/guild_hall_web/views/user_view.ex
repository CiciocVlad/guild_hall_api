defmodule GuildHallWeb.UserView do
  use GuildHallWeb, :view
  alias GuildHallWeb.UserView
  alias GuildHallWeb.AttributeView
  alias GuildHallWeb.ProjectView
  alias GuildHallWeb.QuoteView
  alias GuildHallWeb.ArticleView

  def render("index.json", %{users: users}), do: render_many(users, UserView, "user_minimum.json")

  def render("list_users.json", %{users: users, off_today: off_today}),
    do:
      users
      |> Enum.map(fn user -> render("user_with_status.json", user: user, off_today: off_today) end)

  def render("index_data.json", %{data: data}), do: render_many(data, UserView, "data.json")

  def render("min_index.json", %{users: users}),
    do: render_many(users, UserView, "avatar.json")

  def render("show.json", %{user: user}), do: render_one(user, UserView, "user_one.json")

  def render("show_minimum.json", %{user: user}),
    do: render_one(user, UserView, "user_minimum.json")

  def render("tehnical_profile.json", %{
        user: user,
        soft_skills: soft_skills,
        department: department
      }) do
    user
    |> Map.from_struct()
    |> Map.take(
      ~w/name avatar email bio years_of_experience number_of_industries number_of_projects job_title preferred_name/a
    )
    |> Map.merge(%{
      soft_skills: soft_skills,
      department: department
    })
  end

  def render("roles.json", %{roles: roles, department: department}),
    do: %{
      roles: roles,
      department: department
    }

  def render("user_one.json", %{user: user}),
    do:
      user
      |> Map.from_struct()
      |> Map.drop(~w/__meta__ inserted_at updated_at pto/a)
      |> Map.merge(%{
        attributes: render_many(user.attributes, AttributeView, "attribute.json", as: :attribute),
        projects: render_many(user.projects, ProjectView, "project.json", as: :project),
        quotes: render_many(user.quotes, QuoteView, "quote.json", as: :quote),
        articles: render_many(user.articles, ArticleView, "article.json", as: :article)
      })

  def render("user_minimum.json", %{user: user}),
    do:
      user
      |> Map.from_struct()
      |> Map.drop(~w/__meta__ inserted_at updated_at projects attributes pto articles quotes/a)

  def render("technologies.json", %{technologies: technologies}) do
    technologies
  end

  def render("user_with_status.json", %{user: user, off_today: off_today}),
    do:
      user
      |> Map.from_struct()
      |> Map.drop(~w/__meta__ inserted_at updated_at projects pto articles quotes/a)
      |> Map.put(:is_working, user.email not in off_today)
      |> Map.merge(%{
        attributes: render_many(user.attributes, AttributeView, "attribute.json", as: :attribute)
      })

  def render("avatar.json", %{user: user}),
    do: user

  def render("data.json", %{user: data}),
    do:
      %{
        project:
          data
          |> Map.keys()
          |> hd()
          |> Map.from_struct()
          |> Map.drop(~w/__meta__ inserted_at updated_at users/a)
      }
      |> Map.merge(data |> Map.values() |> hd())
end
