defmodule GuildHall.Accounts do
  alias GuildHall.Users
  alias GuildHall.Users.User
  alias GuildHall.PTODays

  @doc """
  Updates a user account with the data received as parameter, using the `email` field for identification.
  If the user is not found a new one is created.

  The following user fields are set:
  - `email` => `data["email"]`
  - `name` => `data["name"]`
  - `avatar` => `data["picture"]`
  - `preferred_name` => `data["given_name"]`

  For new users the `joined_date` field is set to the current UTC date.

  Returns the synced user.
  """
  def sync_user(%{"email" => email} = data) do
    user_params = %{
      "name" => data["name"],
      "avatar" => data["picture"],
      "email" => data["email"],
      "preferred_name" => data["given_name"]
    }

    case Users.get_by_email(email) do
      nil ->
        {:ok, user} =
          user_params
          |> Map.merge(%{
            "joined_date" => Date.utc_today(),
            "hobbies" => [],
            "social_media" => %{}
          })
          |> Users.create_user()

        PTODays.create_pto(%{days: 21, year: DateTime.utc_now().year, user_id: user.id})

        {:ok, user}

      %User{} = user ->
        user
        |> Users.update_user(user_params)
    end
  end
end
