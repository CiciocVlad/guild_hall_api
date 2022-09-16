defmodule GuildHall.CategoriesTest do
  use GuildHall.DataCase

  alias GuildHall.Categories
  alias GuildHall.Categories.Category

  test "list_categories/0 returns all categories in alphabetical order" do
    inserted = Factory.insert_list(3, :category)

    named =
      Categories.named()
      |> Enum.map(fn atom ->
        Categories.name!(atom)
      end)

    result = Categories.list_categories()

    expected_names =
      inserted
      |> Enum.map(fn c -> c.name end)
      |> Kernel.++(named)
      |> Enum.sort()

    assert expected_names == Enum.map(result, fn c -> c.name end)

    assert Enum.sort_by(inserted, fn c -> c.name end) ==
             Enum.filter(result, fn c -> c.name not in named end)
  end

  describe "get_category/1" do
    test "returns the category with the given id" do
      category = Factory.insert(:category)

      assert Categories.get_category(category.id) == category
    end

    test "returns nil when the category with the given id is not found" do
      refute Categories.get_category(Ecto.UUID.generate())
    end
  end

  describe "get_category!/1" do
    test "returns the category with the given id" do
      category = Factory.insert(:category)

      assert Categories.get_category!(category.id) == category
    end

    test "raises when the category with the given id is not found" do
      assert_raise(Ecto.NoResultsError, fn -> Categories.get_category!(Ecto.UUID.generate()) end)
    end
  end

  describe "create_category/1" do
    setup :add_start_timestamp

    test "creates a category with valid data", %{start_timestamp: start_timestamp} do
      input_data = Factory.string_params_for(:category)
      assert {:ok, %Category{} = category} = Categories.create_category(input_data)

      assert category == Repo.get(Category, category.id)

      returned_data =
        category
        |> string_params_map()
        |> Map.drop(~w[id inserted_at updated_at])

      assert returned_data == input_data

      assert category.inserted_at == category.updated_at
      assert NaiveDateTime.compare(category.inserted_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data" do
      input_data = Factory.string_params_for(:invalid_category)

      assert {:error, %Ecto.Changeset{} = changeset} = Categories.create_category(input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)
    end

    test "returns an error changeset with a duplicate name (case-insensitive)" do
      existing_category = Factory.insert(:category)

      input_data =
        Factory.string_params_for(:category, name: String.upcase(existing_category.name))

      assert {:error, %Ecto.Changeset{} = changeset} = Categories.create_category(input_data)

      assert {:name, _} = hd(changeset.errors)
    end
  end

  describe "update_category/2" do
    setup :add_start_timestamp

    setup do
      %{original: Factory.insert(:category)}
    end

    test "updates the category with valid data", %{
      original: original,
      start_timestamp: start_timestamp
    } do
      input_data = Factory.string_params_for(:category)
      assert {:ok, %Category{} = category} = Categories.update_category(original, input_data)

      assert category == Repo.get(Category, category.id)

      returned_data =
        category
        |> string_params_map()
        |> Map.drop(~w[id inserted_at updated_at])

      assert returned_data == input_data

      assert category.inserted_at == original.inserted_at
      assert NaiveDateTime.compare(category.inserted_at, category.updated_at) in [:eq, :lt]
      assert NaiveDateTime.compare(category.updated_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data", %{original: original} do
      input_data = Factory.string_params_for(:invalid_category)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Categories.update_category(original, input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)

      assert original == Repo.get(Category, original.id)
    end

    test "returns an error changeset with a duplicate name (case-insensitive)", %{
      original: original
    } do
      duplicated = Factory.insert(:category)

      input_data = Factory.string_params_for(:category, name: String.downcase(duplicated.name))

      assert {:error, %Ecto.Changeset{} = changeset} =
               Categories.update_category(original, input_data)

      assert [{:name, _}] = changeset.errors
    end
  end

  test "delete_category/1 deletes the category" do
    category = Factory.insert(:category)
    assert {:ok, %Category{}} = Categories.delete_category(category)

    assert is_nil(Repo.get(Category, category.id))
  end

  describe "get_named_category/1" do
    test "returns the named category when it exists" do
      expected_name = Categories.name!(:soft_skill)
      assert %Category{name: ^expected_name} = Categories.get_named_category(:soft_skill)
    end

    test "raises with a string as parameter" do
      assert_raise(FunctionClauseError, fn -> Categories.get_named_category("Technology") end)
    end

    test "raises with an unknown named category" do
      assert_raise(KeyError, fn -> Categories.get_named_category(:unknown) end)
    end

    test "returns nil when a category with the given name is not found" do
      {:ok, _} =
        :technology
        |> Categories.get_named_category()
        |> Repo.delete()

      refute Categories.get_named_category(:technology)
    end
  end
end
