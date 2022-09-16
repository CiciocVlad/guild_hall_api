defmodule GuildHallWeb.AttributeController do
  use GuildHallWeb, :controller

  alias GuildHall.Attributes
  alias GuildHall.Attributes.Attribute
  alias GuildHall.UsersAttributes
  alias GuildHall.UsersAttributes.UserAttribute
  alias GuildHallWeb.UserAttributeView
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    attributes = Attributes.list_attributes_with_category()
    conn |> render("index_category.json", attributes: attributes)
  end

  def create(conn, %{"attribute" => attribute_params}) do
    with {:ok, %Attribute{} = attribute} <- Attributes.create_attribute(attribute_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.attribute_path(conn, :show, attribute))
      |> render("show.json", attribute: attribute)
    else
      {:error, _} -> conn |> HttpUtils.bad_request("could not create attribute")
    end
  end

  def get_filters(conn, _params) do
    filters = Attributes.get_filters()
    conn |> json(filters)
  end

  def show(conn, %{"id" => id}) do
    attribute = Attributes.get_attribute_with_category(id)
    conn |> render("show_category.json", attribute: attribute)
  end

  def update(conn, %{"id" => id, "attribute" => attribute_params}) do
    with {:get_attribute, %Attribute{} = attribute} <-
           {:get_attribute, Attributes.get_attribute(id)},
         {:update_attribute, {:ok, %Attribute{} = updated_attribute}} <-
           {:update_attribute, Attributes.update_attribute(attribute, attribute_params)} do
      conn |> render("show.json", attribute: updated_attribute)
    else
      {:get_attribute, _} -> conn |> HttpUtils.not_found("attribute not found")
      {:update_attribute, _} -> conn |> HttpUtils.bad_request("could not update attribute")
    end
  end

  def update_is_favorite(conn, %{
        "attribute_id" => attribute_id,
        "user_id" => user_id,
        "is_favorite" => is_favorite
      }) do
    with {:get_user_attribute, %UserAttribute{} = user_attribute} <-
           {:get_user_attribute, UsersAttributes.get_attribute_for_user_id(user_id, attribute_id)},
         {:update_user_attribute, {:ok, %UserAttribute{} = updated_user_attribute}} <-
           {:update_user_attribute,
            UsersAttributes.update_user_attribute(user_attribute, %{is_favorite: is_favorite})} do
      conn
      |> put_view(UserAttributeView)
      |> render("show.json", user_attribute: updated_user_attribute)
    else
      {:get_user_attribute, _} -> conn |> HttpUtils.not_found("attribute not found")
      {:update_user_attribute, _} -> conn |> HttpUtils.bad_request("could not update attribute")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_attribute, %Attribute{} = attribute} <-
           {:get_attribute, Attributes.get_attribute(id)},
         {:delete_attribute, {:ok, %Attribute{}}} <-
           {:delete_attribute, Attributes.delete_attribute(attribute)} do
      conn |> json(%{})
    else
      {:get_attribute, _} -> conn |> HttpUtils.not_found("attribute not found")
      {:delete_attribute, _} -> conn |> HttpUtils.bad_request("could not delete attribute")
    end
  end
end
