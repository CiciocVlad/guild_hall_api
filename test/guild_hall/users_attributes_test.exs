defmodule GuildHall.UsersAttributesTest do
  use GuildHall.DataCase

  alias GuildHall.Users

  describe "get_attributes/2" do
    setup do
      user = Factory.insert(:user)
      category = Factory.insert(:category)
      other_category = Factory.insert(:category)

      attributes = [
        Factory.insert(:attribute, category_id: category.id, name: "Other name"),
        Factory.insert(:attribute, category_id: category.id, name: "Not favorite"),
        Factory.insert(:attribute, category_id: other_category.id, name: "Favorite")
      ]

      projects = Factory.insert_list(3, :project)

      for a <- attributes do
        Factory.insert(:user_attribute,
          attribute_id: a.id,
          user_id: user.id,
          is_favorite: false
        )

        for p <- projects do
          Factory.insert(:user_attribute,
            attribute_id: a.id,
            user_id: user.id,
            project_id: p.id,
            is_favorite: a.name == "Favorite" and p == hd(projects)
          )
        end
      end

      {:ok,
       user: user, category: category, other_category: other_category, attributes: attributes}
    end

    test "returns a list of sorted attributes for a user and a category name (unique attributes)",
         %{
           user: user,
           category: category,
           attributes: attributes,
           other_category: other_category
         } do
      assert Users.get_attributes(user.id, category.name) ==
               attributes
               |> Enum.reverse()
               |> Enum.filter(fn attr -> attr.category_id == category.id end)
               |> Enum.map(fn attr ->
                 attr
                 |> Map.take([:id, :name])
                 |> Map.put(:is_favorite, false)
               end)

      assert Users.get_attributes(user.id, other_category.name) ==
               attributes
               |> Enum.reverse()
               |> Enum.filter(fn attr -> attr.category_id == other_category.id end)
               |> Enum.map(fn attr ->
                 attr
                 |> Map.take([:id, :name])
                 |> Map.put(:is_favorite, true)
               end)
    end

    test "returns an empty list when the user doesn't have any attributes", %{category: category} do
      user = Factory.insert(:user)

      assert Users.get_attributes(user.id, category.name) == []
    end

    test "returns an empty list when a category with the given name doesn't exist", %{user: user} do
      assert Users.get_attributes(user.id, "no name") == []
    end

    test "returns an empty list when the user doesn't exist", %{category: category} do
      assert Users.get_attributes(Ecto.UUID.generate(), category.name) == []
    end
  end

  describe "get_roles/2" do
    setup do
      user = Factory.insert(:user)

      projects = Factory.insert_list(3, :project)

      roles = [
        Factory.insert(:role, title: "Supervisor"),
        Factory.insert(:role, title: "Idler"),
        Factory.insert(:role, title: "Worker")
      ]

      for idx <- 0..(length(projects) - 1) do
        Factory.insert(:user_project,
          user_id: user.id,
          project_id: Enum.at(projects, idx).id,
          role_id: Enum.at(roles, rem(idx, length(roles))).id
        )
      end

      {:ok, user: user}
    end

    test "returns a list of sorted unique role titles",
         %{
           user: user
         } do
      assert Users.get_roles(user.id) == ["Idler", "Supervisor", "Worker"]
    end

    test "returns an empty list when the user doesn't have any projects" do
      user = Factory.insert(:user)

      assert Users.get_roles(user.id) == []
    end

    test "returns an empty list when the user doesn't exist" do
      assert Users.get_roles(Ecto.UUID.generate()) == []
    end
  end
end
