defmodule GuildHall.Controllers.UsersSkillsTest do
  use GuildHallWeb.ConnCase

  alias GuildHall.Categories

  describe "without authorisation" do
    test_returns_401("user_path(:get_technologies)", fn conn ->
      get(conn, Routes.user_path(conn, :get_technologies, Ecto.UUID.generate()))
    end)

    test_returns_401("user_path(:get_roles)", fn conn ->
      get(conn, Routes.user_path(conn, :get_roles, Ecto.UUID.generate()))
    end)
  end

  describe "user_path(:get_technologies)" do
    setup :create_and_authorise_user

    test "returns the technologies for an existing user in alphabetical order", %{
      conn: conn,
      user: user
    } do
      technology_category = Categories.get_named_category(:technology)

      attributes = [
        Factory.insert(:attribute, category_id: technology_category.id, name: "Favorite"),
        Factory.insert(:attribute, category_id: technology_category.id, name: "Not favorite"),
        Factory.insert(:attribute, category_id: technology_category.id, name: "Z")
      ]

      projects = Factory.insert_list(3, :project)

      for a <- attributes, p <- projects do
        Factory.insert(:user_attribute,
          attribute_id: a.id,
          user_id: user.id,
          project_id: p.id,
          is_favorite: a.name == "Favorite"
        )
      end

      conn =
        conn
        |> get(Routes.user_path(conn, :get_technologies, user.id))

      assert json_response(conn, 200) ==
               attributes
               |> Enum.map(fn attr ->
                 attr
                 |> Map.take([:id, :name])
                 |> Map.put(:is_favorite, attr.name == "Favorite")
                 |> map_with_string_keys()
               end)
    end

    test "returns an empty list when the :technology category is missing", %{
      conn: conn,
      user: user
    } do
      Repo.delete(Categories.get_named_category(:technology))

      conn =
        conn
        |> get(Routes.user_path(conn, :get_technologies, user.id))

      assert json_response(conn, 200) == []
    end

    test_returns_404_with_random_id("could not find user", fn conn, value ->
      get(conn, Routes.user_path(conn, :get_technologies, value))
    end)
  end

  describe "user_path(:get_roles)" do
    setup :create_and_authorise_user

    test "returns the department and roles for an existing user", %{
      conn: conn,
      user: user
    } do
      department_category = Categories.get_named_category(:department)

      department =
        Factory.insert(:attribute,
          category_id: department_category.id,
          name: "Anomalous Materials"
        )

      Factory.insert(:user_attribute,
        attribute_id: department.id,
        user_id: user.id
      )

      projects = Factory.insert_list(3, :project)
      roles = Factory.insert_list(2, :role)

      for idx <- 0..(length(projects) - 1) do
        Factory.insert(:user_project,
          user_id: user.id,
          project_id: Enum.at(projects, idx).id,
          role_id: Enum.at(roles, rem(idx, length(roles))).id
        )
      end

      conn =
        conn
        |> get(Routes.user_path(conn, :get_roles, user.id))

      assert %{
               "department" => actual_department_name,
               "roles" => actual_roles
             } = json_response(conn, 200)

      assert actual_department_name == department.name
      assert MapSet.new(actual_roles) == MapSet.new(roles, fn role -> role.title end)
    end

    test "returns nil and empty list for a user that doesn't have any records", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> get(Routes.user_path(conn, :get_roles, user.id))

      assert %{
               "department" => nil,
               "roles" => []
             } == json_response(conn, 200)
    end

    test "returns one of the values for department when there are several attributes in the category",
         %{
           conn: conn,
           user: user
         } do
      department_category = Categories.get_named_category(:department)
      departments = Factory.insert_list(3, :attribute, category_id: department_category.id)

      for department <- departments do
        Factory.insert(:user_attribute,
          attribute_id: department.id,
          user_id: user.id
        )
      end

      conn =
        conn
        |> get(Routes.user_path(conn, :get_roles, user.id))

      assert %{
               "department" => department_name
             } = json_response(conn, 200)

      assert department_name in Enum.map(departments, fn attr -> attr.name end)
    end

    test "returns nil for department when the department category doesn't exist", %{
      conn: conn,
      user: user
    } do
      {:ok, _} = Repo.delete(Categories.get_named_category(:department))

      conn =
        conn
        |> get(Routes.user_path(conn, :get_roles, user.id))

      assert %{
               "department" => nil
             } = json_response(conn, 200)
    end

    test_returns_404_with_random_id("could not find user", fn conn, value ->
      get(conn, Routes.user_path(conn, :get_roles, value))
    end)
  end
end
