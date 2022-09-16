defmodule GuildHall.Controllers.UsersCrudTest do
  use GuildHallWeb.ConnCase

  describe "without authorisation" do
    test_returns_401("user_path(:get_technologies)", fn conn ->
      get(conn, Routes.user_path(conn, :show, Ecto.UUID.generate()))
    end)
  end

  describe "user_path(:show)" do
    setup :create_and_authorise_user

    test_returns_404_with_random_id("could not find user", fn conn, value ->
      get(conn, Routes.user_path(conn, :show, value))
    end)
  end
end
