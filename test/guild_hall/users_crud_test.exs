defmodule GuildHall.UsersCRUDTest do
  use GuildHall.DataCase

  alias GuildHall.Users
  alias GuildHall.Users.User

  @user_defaults %{
    "hobbies" => nil,
    "is_admin" => false,
    "number_of_industries" => "0",
    "number_of_projects" => "0",
    "phone" => nil,
    "social_media" => nil,
    "years_of_experience" => "0",
    "left_date" => nil,
    "bio" => nil,
    "job_title" => nil
  }

  test "list_users/0 returns all users, sorted by name, left ones last" do
    users =
      Factory.insert_list(2, :user, attributes: [], left_date: nil) ++
        Factory.insert_list(2, :user, attributes: []) ++
        Factory.insert_list(2, :user, attributes: [], left_date: nil)

    assert Users.list_users() ==
             users
             |> Enum.sort_by(fn user -> {not is_nil(user.left_date), user.name} end)
  end

  describe "get_user/1" do
    test "returns the user with the given id (with preloaded associations)" do
      user =
        Factory.insert(:user, pto: [], attributes: [], projects: [], articles: [], quotes: [])

      assert Users.get_user(user.id) == user
    end

    for {name, value} <- [{"valid UUID", Ecto.UUID.generate()}, {"invalid UUID", "invalid UUID"}] do
      test "returns nil when the user with the given id is not found (#{name})" do
        refute Users.get_user(unquote(value))
      end
    end
  end

  describe "get_user!/1" do
    test "returns the user with the given id (with preloaded associations)" do
      user =
        Factory.insert(:user, pto: [], attributes: [], projects: [], articles: [], quotes: [])

      assert Users.get_user!(user.id) == user
    end

    test "raises Ecto.NoResultsError when the user with the given id is not found (valid UUID)" do
      assert_raise(Ecto.NoResultsError, fn -> Users.get_user!(Ecto.UUID.generate()) end)
    end

    test "raises Ecto.NoResultsError when the user with the given id is not found (invalid UUID)" do
      raised = assert_raise(Ecto.NoResultsError, fn -> Users.get_user!("not an UUID") end)

      id = Ecto.UUID.generate()

      template =
        try do
          Users.get_user!(id)
        rescue
          e in Ecto.NoResultsError ->
            e
        end

      # should raise the same exception
      assert inspect(raised) == String.replace(inspect(template), id, "not an UUID")
    end
  end

  describe "create_user/1" do
    setup :add_start_timestamp

    test "creates a user with valid data", %{start_timestamp: start_timestamp} do
      input_data = Factory.string_params_for(:user)
      assert {:ok, %User{} = user} = Users.create_user(input_data)

      assert user == Repo.get(User, user.id)

      returned_data =
        user
        |> string_params_map()
        |> Map.drop(~w[id attributes projects pto inserted_at updated_at articles quotes])

      assert returned_data == input_data

      assert user.inserted_at == user.updated_at
      assert NaiveDateTime.compare(user.inserted_at, start_timestamp) in [:eq, :gt]
    end

    test "creates a user with valid data excluding defaults" do
      input_data =
        :user
        |> Factory.string_params_for()
        |> Map.drop(Map.keys(@user_defaults))

      assert {:ok, %User{} = user} = Users.create_user(input_data)

      assert user == Repo.get(User, user.id)

      returned_data =
        user
        |> string_params_map()
        |> Map.drop(~w[id attributes projects pto inserted_at updated_at articles quotes])

      assert returned_data == Map.merge(input_data, @user_defaults)
    end

    test "returns an error changeset with invalid data" do
      input_data = Factory.string_params_for(:invalid_user)

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)
    end

    test "returns an error changeset with a duplicate email" do
      existing_user = Factory.insert(:user)

      input_data = Factory.string_params_for(:user, email: existing_user.email)

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(input_data)

      assert {:email, _} = hd(changeset.errors)
    end
  end

  describe "update_user/2" do
    setup :add_start_timestamp

    setup do
      %{original: Factory.insert(:user)}
    end

    test "updates the user with valid data", %{
      original: original,
      start_timestamp: start_timestamp
    } do
      input_data = Factory.string_params_for(:user)
      assert {:ok, %User{} = user} = Users.update_user(original, input_data)

      assert user == Repo.get(User, user.id)

      returned_data =
        user
        |> string_params_map()
        |> Map.drop(~w[id attributes projects pto inserted_at updated_at articles quotes])

      assert returned_data == input_data

      assert NaiveDateTime.compare(user.inserted_at, user.updated_at) in [:eq, :lt]
      assert NaiveDateTime.compare(user.updated_at, start_timestamp) in [:eq, :gt]
    end

    test "returns an error changeset with invalid data", %{original: original} do
      input_data = Factory.string_params_for(:invalid_user)
      assert {:error, %Ecto.Changeset{} = changeset} = Users.update_user(original, input_data)

      assert Enum.count(changeset.errors) == Enum.count(input_data)

      assert original == Repo.get(User, original.id)
    end

    test "returns an error changeset with a duplicate email", %{original: original} do
      duplicated = Factory.insert(:user)

      input_data = Factory.string_params_for(:user, email: duplicated.email)

      assert {:error, %Ecto.Changeset{} = changeset} = Users.update_user(original, input_data)

      assert [{:email, _}] = changeset.errors
    end
  end

  test "delete_user/1 deletes the user" do
    user = Factory.insert(:user)
    assert {:ok, %User{}} = Users.delete_user(user)

    assert is_nil(Repo.get(User, user.id))
  end

  describe "get_by_email/1" do
    test "returns the user with the given email when it exists" do
      user = Factory.insert(:user)

      assert found_user = Users.get_by_email(user.email)

      assert user == found_user
    end

    test "returns nil when a user with the given email is not found" do
      refute Users.get_by_email("some email")
    end
  end
end
