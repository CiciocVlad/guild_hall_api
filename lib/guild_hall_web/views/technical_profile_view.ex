defmodule GuildHallWeb.TechnicalProfileView do
  use GuildHallWeb, :view
  alias GuildHallWeb.UserView

  def render("show.json", %{
        user: user,
        soft_skills: soft_skills,
        department: department,
        technologies: technologies,
        industries: industries,
        skills: skills,
        projects: projects
      }),
      do: %{
        user:
          UserView.render("tehnical_profile.json", %{
            user: user,
            soft_skills: soft_skills,
            department: department
          }),
        technologies: technologies,
        industries: industries,
        skills: skills,
        projects: projects
      }
end
