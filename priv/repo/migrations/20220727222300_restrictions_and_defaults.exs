defmodule GuildHall.Repo.Migrations.RestrictionsAndDefaults do
  use Ecto.Migration
  import Ecto.Query

  def change do
    # users
    alter table("users") do
      modify(:email, :string, null: false)
      modify(:name, :string, null: false)
    end

    execute("UPDATE \"users\" SET joined_date = '1970-01-01' WHERE joined_date IS NULL")

    alter table("users") do
      modify(:joined_date, :date, null: false)
    end

    execute("UPDATE \"users\" SET preferred_name = name WHERE preferred_name IS NULL")

    alter table("users") do
      modify(:preferred_name, :string, null: false)
    end

    {_count, nil} =
      from(
        s in "users",
        where: is_nil(s.number_of_industries)
      )
      |> repo().update_all(set: [number_of_industries: "0"])

    alter table("users") do
      modify(:number_of_industries, :string, null: false, default: "0")
    end

    {_count, nil} =
      from(
        s in "users",
        where: is_nil(s.number_of_projects)
      )
      |> repo().update_all(set: [number_of_projects: "0"])

    alter table("users") do
      modify(:number_of_projects, :string, null: false, default: "0")
    end

    {_count, nil} =
      from(
        s in "users",
        where: is_nil(s.years_of_experience)
      )
      |> repo().update_all(set: [years_of_experience: "0"])

    alter table("users") do
      modify(:years_of_experience, :string, null: false, default: "0")
    end

    # categories
    alter table("categories") do
      modify(:name, :string, null: false)
    end

    # attributes
    alter table("attributes") do
      modify(:category_id, :uuid, null: false)
      modify(:name, :string, null: false)
    end

    execute("DELETE FROM \"user_attribute\" WHERE attribute_id IS NULL")

    # user_attribute
    alter table("user_attribute") do
      modify(:attribute_id, :uuid, null: false)
      modify(:user_id, :uuid, null: false)
    end

    # projects
    alter table("projects") do
      modify(:category, :string, null: false)
      modify(:description, :text, null: false)
      modify(:title, :string, null: false)
    end

    # users_projects
    alter table("users_projects") do
      modify(:project_id, :uuid, null: false)
      modify(:user_id, :uuid, null: false)
    end

    # pto
    alter table("pto") do
      modify(:days, :integer, null: false)
      modify(:user_id, :uuid, null: false)
      modify(:year, :integer, null: false)
    end

    # roles
    alter table("roles") do
      modify(:title, :string, null: false)
    end

    # redirect_urls
    alter table("redirect_urls") do
      modify(:user_id, :uuid, null: false)
    end

    # best_of_quotes
    alter table("best_of_quotes") do
      modify(:quote, :string, null: false)
      modify(:user_id, :uuid, null: false)
    end

    # articles
    alter table("articles") do
      modify(:link, :string, null: false)
      modify(:user_id, :uuid, null: false)
    end
  end
end
