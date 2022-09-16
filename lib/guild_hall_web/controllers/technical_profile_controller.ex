defmodule GuildHallWeb.TechnicalProfileController do
  use GuildHallWeb, :controller
  alias GuildHall.Users
  alias GuildHall.Attributes
  alias GuildHall.Categories
  alias GuildHallWeb.HttpUtils

  defp intersect(user_attributes, attributes, category) do
    user_attributes
    |> MapSet.intersection(
      attributes
      |> Enum.filter(fn attribute -> attribute.category_name == category end)
      |> Enum.map(fn attr -> attr.name end)
      |> MapSet.new()
    )
    |> MapSet.to_list()
  end

  def show(conn, %{"mapping" => mapping}) do
    user = Users.get_user_by_mapping(mapping)

    attributes =
      Attributes.get_attributes_of_user_on_project(user)
      |> Enum.reduce(%{}, fn value, acc ->
        Map.merge(acc, value, fn _, a, b -> [hd(b) | a] |> List.flatten() end)
      end)

    projects_with_attr =
      attributes
      |> Map.keys()
      |> Enum.map(fn key ->
        %{
          title: key.title,
          user_impact: key.user_impact,
          category: key.category,
          description: key.description,
          attributes:
            if attributes[key] |> hd |> Map.values() |> Enum.any?() do
              attributes[key]
            else
              []
            end
        }
      end)

    if !user do
      conn |> HttpUtils.not_found("user not found")
    else
      user_attributes =
        Attributes.list_attributes_for_user(user.id)
        |> Enum.map(fn attr -> attr.name end)
        |> MapSet.new()

      all_attributes = Attributes.list_attributes_with_category()

      soft_skills = user_attributes |> intersect(all_attributes, Categories.name!(:soft_skill))
      department = user_attributes |> intersect(all_attributes, Categories.name!(:department))
      technologies = user_attributes |> intersect(all_attributes, Categories.name!(:technology))
      industries = user_attributes |> intersect(all_attributes, Categories.name!(:industry))
      skills = user_attributes |> intersect(all_attributes, Categories.name!(:hard_skill))

      conn
      |> render("show.json",
        user: user,
        soft_skills: soft_skills,
        department: department,
        technologies: technologies,
        industries: industries,
        skills: skills,
        projects: projects_with_attr
      )
    end
  end
end
