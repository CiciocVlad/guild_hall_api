defmodule GuildHall.AttributesTest do
  use GuildHall.DataCase

  alias GuildHall.Attributes
  alias GuildHall.Attributes.Attribute

  setup do
    {:ok, category: Factory.insert(:category)}
  end

  test "list_attributes/0 returns all attributes sorted by name", %{category: category} do
    # number of items inserted in the migration
    assert {346, nil} = Repo.delete_all(Attribute)

    attributes = Factory.insert_list(3, :attribute, category_id: category.id)
    assert Attributes.list_attributes() == Enum.sort_by(attributes, fn attr -> attr.name end)
  end

  describe "get_attribute/1" do
    test "returns the attribute with the given id (with preloaded associations)", %{
      category: category
    } do
      attribute = Factory.insert(:attribute, category_id: category.id)

      assert Attributes.get_attribute(attribute.id) == attribute
    end

    test "returns nil when the attribute with the given id is not found" do
      refute Attributes.get_attribute(Ecto.UUID.generate())
    end
  end

  describe "get_attribute!/1" do
    test "returns the attribute with the given id (with preloaded associations)", %{
      category: category
    } do
      attribute = Factory.insert(:attribute, category_id: category.id)

      assert Attributes.get_attribute!(attribute.id) == attribute
    end

    test "raises when the attribute with the given id is not found" do
      assert_raise(Ecto.NoResultsError, fn -> Attributes.get_attribute!(Ecto.UUID.generate()) end)
    end
  end

  describe "create_attribute/1" do
    setup :add_start_timestamp

    test "creates a attribute with valid data", %{
      start_timestamp: start_timestamp,
      category: category
    } do
      input_data = Factory.string_params_for(:attribute, category_id: category.id)
      assert {:ok, %Attribute{} = attribute} = Attributes.create_attribute(input_data)

      assert attribute == Repo.get(Attribute, attribute.id)

      returned_data =
        attribute
        |> string_params_map()
        |> Map.drop(~w[id category inserted_at updated_at])

      assert returned_data == input_data

      assert attribute.inserted_at == attribute.updated_at
      assert NaiveDateTime.compare(attribute.inserted_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data" do
      input_data = Factory.string_params_for(:invalid_attribute)

      assert {:error, %Ecto.Changeset{} = changeset} = Attributes.create_attribute(input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)
    end

    test "returns an error changeset with a duplicate name inside the category (case insensitive)",
         %{
           category: category
         } do
      existing_attribute = Factory.insert(:attribute, category_id: category.id)

      input_data =
        Factory.string_params_for(:attribute,
          name: String.upcase(existing_attribute.name),
          category_id: category.id
        )

      assert {:error, %Ecto.Changeset{} = changeset} = Attributes.create_attribute(input_data)

      assert {:name, _} = hd(changeset.errors)
    end
  end

  describe "update_attribute/2" do
    setup :add_start_timestamp

    setup(%{category: category}) do
      %{original: Factory.insert(:attribute, category_id: category.id)}
    end

    test "updates the attribute with valid data", %{
      original: original,
      start_timestamp: start_timestamp
    } do
      other_category = Factory.insert(:category)

      input_data = Factory.string_params_for(:attribute, category_id: other_category.id)
      assert {:ok, %Attribute{} = attribute} = Attributes.update_attribute(original, input_data)

      assert attribute == Repo.get(Attribute, attribute.id)

      returned_data =
        attribute
        |> string_params_map()
        |> Map.drop(~w[id category inserted_at updated_at])

      assert returned_data == input_data

      assert attribute.inserted_at == original.inserted_at
      assert NaiveDateTime.compare(attribute.inserted_at, attribute.updated_at) in [:eq, :lt]
      assert NaiveDateTime.compare(attribute.updated_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data", %{original: original} do
      input_data = Factory.string_params_for(:invalid_attribute)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Attributes.update_attribute(original, input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)

      assert original == Repo.get(Attribute, original.id)
    end

    test "returns an error changeset with a duplicate name inside the category (case-insensitive)",
         %{
           original: original,
           category: category
         } do
      duplicated = Factory.insert(:attribute, category_id: category.id)

      input_data = Factory.string_params_for(:attribute, name: String.downcase(duplicated.name))

      assert {:error, %Ecto.Changeset{} = changeset} =
               Attributes.update_attribute(original, input_data)

      assert [{:name, _}] = changeset.errors
    end
  end

  test "delete_attribute/1 deletes the attribute", %{category: category} do
    attribute = Factory.insert(:attribute, category_id: category.id)
    assert {:ok, %Attribute{}} = Attributes.delete_attribute(attribute)

    assert is_nil(Repo.get(Attribute, attribute.id))
  end

  test "list_attributes_with_categories/0 returns all attributes, sorted by name, with category_name" do
    assert {_, nil} = Repo.delete_all(Attribute)

    category = Factory.insert(:category)
    attributes = Factory.insert_list(3, :attribute, category_id: category.id)

    assert Attributes.list_attributes_with_category() ==
             attributes
             |> Enum.sort_by(fn attr -> attr.name end)
             |> Enum.map(fn attr ->
               attr
               |> Map.take([:id, :name])
               |> Map.put(:category_name, category.name)
             end)
  end

  test "get_attribute_with_category/1 returns the attribute with the given id with category_name" do
    category = Factory.insert(:category)
    attribute = Factory.insert(:attribute, category_id: category.id)

    expected =
      attribute
      |> Map.take([:id, :name])
      |> Map.put(:category_name, category.name)

    assert expected == Attributes.get_attribute_with_category(attribute.id)
  end
end
