defmodule GuildHallWeb.CategoryController do
  use GuildHallWeb, :controller

  alias GuildHall.Categories
  alias GuildHall.Categories.Category
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    categories = Categories.list_categories()
    conn |> render("index.json", categories: categories)
  end

  def create(conn, %{"category" => category_params}) do
    with {:ok, %Category{} = category} <-
           Categories.create_category(category_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.category_path(conn, :show, category)
      )
      |> render("show.json", category: category)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("could not create attribute category")
    end
  end

  def show(conn, %{"id" => id}) do
    category = Categories.get_category!(id)
    conn |> render("show.json", category: category)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    with {:get_category, %Category{} = category} <-
           {:get_category, Categories.get_category(id)},
         {:update_category, {:ok, %Category{} = updated_category}} <-
           {:update_category,
            Categories.update_category(
              category,
              category_params
            )} do
      conn |> render("show.json", category: updated_category)
    else
      {:get_category, _} ->
        conn |> HttpUtils.not_found("attribute category not found")

      {:update_category, _} ->
        conn |> HttpUtils.bad_request("could not update attribute category")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_category, %Category{} = category} <-
           {:get_category, Categories.get_category(id)},
         {:delete_category, {:ok, %Category{}}} <-
           {:delete_category, Categories.delete_category(category)} do
      conn |> json(%{})
    else
      {:get_category, _} ->
        conn |> HttpUtils.not_found("attribute category not found")

      {:delete_category, _} ->
        conn |> HttpUtils.bad_request("could not delete attribute category")
    end
  end
end
