defmodule GuildHall.AccountsSyncTest do
  use GuildHall.DataCase

  alias GuildHall.Accounts
  alias GuildHall.Users.User

  defp create_user_with_pto(_context) do
    %{id: id} =
      Factory.insert(:user,
        email: "email",
        pto:
          for(
            diff <- 0..2,
            do: Factory.build(:pto, year: Date.utc_today().year - diff, days: 21 - diff)
          )
      )

    {:ok,
     existing_user:
       User
       |> Repo.get(id)
       |> Repo.preload(:pto)}
  end

  defp run_sync_user(_context) do
    utc_now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()

    params =
      for field <- ["name", "picture", "email", "given_name", "aud", "iss"],
          do: {field, field},
          into: %{}

    assert {:ok, user} = Accounts.sync_user(params)

    %{timestamp: utc_now, result: user}
  end

  for user_exists <- [true, false] do
    name_part =
      if user_exists do
        "user exists"
      else
        "user does not exist"
      end

    describe "sync_user/1 (common) when #{name_part}" do
      setup if(user_exists, do: [:create_user_with_pto], else: []) ++ [:run_sync_user]

      test "saves the user data", %{result: user} do
        assert user == Repo.get(User, user.id)
      end

      test "returns data matching input data", %{result: user} do
        returned_data =
          user
          |> string_params_map()

        expected_partial_data = %{
          "name" => "name",
          "avatar" => "picture",
          "email" => "email",
          "preferred_name" => "given_name"
        }

        assert Map.take(returned_data, Map.keys(expected_partial_data)) == expected_partial_data
      end
    end
  end

  describe "sync/1 when user does not exist" do
    setup [:run_sync_user]

    test "sets empty hobbies and social media links", %{result: user} do
      assert user.hobbies == []
      assert user.social_media == %{}
    end

    test "sets the timestamps", %{result: user, timestamp: timestamp} do
      assert user.inserted_at == user.updated_at
      assert NaiveDateTime.compare(user.inserted_at, timestamp) in [:eq, :gt]

      assert user.joined_date == Date.utc_today()
    end

    test "creates a user PTO record with the default number of days", %{
      result: user,
      timestamp: timestamp
    } do
      saved_user =
        User
        |> Repo.get(user.id)
        |> Repo.preload(:pto)

      assert Enum.map(saved_user.pto, fn item ->
               item
               |> Map.from_struct()
               |> Map.take([:year, :days, :user_id])
             end) == [
               %{year: timestamp.year, days: 21, user_id: user.id}
             ]
    end
  end

  describe "sync_user/1 when user exists" do
    setup [:create_user_with_pto, :run_sync_user]

    test "sets the timestamps", %{result: user, timestamp: timestamp} do
      assert NaiveDateTime.compare(user.inserted_at, user.updated_at) in [:eq, :lt]
      assert NaiveDateTime.compare(user.updated_at, timestamp) in [:eq, :gt]
    end

    test "doesn't touch the user data except name, avatar and preferred_name", %{
      result: user,
      existing_user: existing_user
    } do
      saved_user =
        User
        |> Repo.get(user.id)
        |> Repo.preload(:pto)
        |> Map.merge(Map.take(existing_user, [:name, :avatar, :preferred_name]))

      assert saved_user == existing_user
    end
  end
end
