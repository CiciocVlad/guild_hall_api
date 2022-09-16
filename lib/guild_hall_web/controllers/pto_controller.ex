defmodule GuildHallWeb.PTOController do
  use GuildHallWeb, :controller

  alias GuildHall.PTODays
  alias GuildHall.PTODays.PTO
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    pto_days = PTODays.list_pto()
    conn |> render("index.json", pto_days: pto_days)
  end

  def create(conn, %{"pto" => pto_params}) do
    with {:unique_year, nil} <-
           {:unique_year,
            PTODays.get_pto_of_user(pto_params["user_id"])
            |> Enum.find(fn pto -> pto.year |> Decimal.to_integer() == pto_params["year"] end)},
         {:ok, %PTO{} = pto} <- PTODays.create_pto(pto_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.pto_path(conn, :show, pto))
      |> render("show.json", pto: pto)
    else
      {:unique_year, _} ->
        conn |> HttpUtils.bad_request("already set the days for given year")

      {:error, _} ->
        conn |> HttpUtils.bad_request("could not create pto")
    end
  end

  def show(conn, %{"id" => id}) do
    pto = PTODays.get_pto!(id)
    conn |> render("show.json", pto: pto)
  end

  def update(conn, %{"id" => id, "pto" => pto_params}) do
    with {:get_pto, %PTO{} = pto} <- {:get_pto, PTODays.get_pto!(id)},
         {:update_pto, {:ok, %PTO{} = updated_pto}} <-
           {:update_pto, PTODays.update_pto(pto, pto_params)} do
      conn |> render("show.json", pto: updated_pto)
    else
      {:get_pto, _} ->
        conn |> HttpUtils.not_found("pto not found")

      {:update_pto, _} ->
        conn |> HttpUtils.bad_request("could not update pto")
    end
  end

  def update_for_user(conn, %{"email" => email, "pto" => pto_params}) do
    year = Date.utc_today().year

    with {:get_pto, %PTO{} = pto} <-
           {:get_pto, PTODays.get_pto_for_user_email_and_year(email, year)},
         {:update_pto, {:ok, %PTO{} = updated_pto}} <-
           {:update_pto, PTODays.update_pto(pto, pto_params)} do
      conn |> render("show.json", pto: updated_pto)
    else
      {:get_pto, _} -> conn |> HttpUtils.not_found("pto not found")
      {:update_pto, _} -> conn |> HttpUtils.bad_request("could not update pto")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_pto, %PTO{} = pto} <- {:get_pto, PTODays.get_pto!(id)},
         {:delete_pto, {:ok, %PTO{}}} <- {:delete_pto, PTODays.delete_pto(pto)} do
      conn |> json(%{})
    else
      {:get_pto, _} ->
        conn |> HttpUtils.not_found("pto not found")

      {:delete_pto, _} ->
        conn |> HttpUtils.bad_request("could not delete pto")
    end
  end
end
