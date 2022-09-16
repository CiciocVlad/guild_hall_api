defmodule GuildHallWeb.RedirectUrlController do
  use GuildHallWeb, :controller

  alias GuildHall.RedirectUrls
  alias GuildHall.RedirectUrls.RedirectUrl
  alias GuildHallWeb.HttpUtils

  def index(conn, _params) do
    redirect_urls = RedirectUrls.list_redirect_urls()
    conn |> render("index.json", redirect_urls: redirect_urls)
  end

  def create(conn, %{"redirect_url" => redirect_url_params}) do
    with {:ok, %RedirectUrl{} = redirect_url} <-
           RedirectUrls.create_redirect_url(redirect_url_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.redirect_url_path(conn, :show, redirect_url))
      |> render("show.json", redirect_url: redirect_url)
    else
      {:error, _} ->
        conn |> HttpUtils.bad_request("could not create redirect url")
    end
  end

  def show(conn, %{"id" => id}) do
    redirect_url = RedirectUrls.get_redirect_url!(id)
    conn |> render("show.json", redirect_url: redirect_url)
  end

  def update(conn, %{"id" => id, "redirect_url" => redirect_url_params}) do
    with {:get_redirect_url, %RedirectUrl{} = redirect_url} <-
           {:get_redirect_url, RedirectUrls.get_redirect_url(id)},
         {:update_redirect_url, {:ok, %RedirectUrl{} = updated_redirect_url}} <-
           {:update_redirect_url,
            RedirectUrls.update_redirect_url(redirect_url, redirect_url_params)} do
      conn |> render("show.json", redirect_url: updated_redirect_url)
    else
      {:get_redirect_url, _} ->
        HttpUtils.not_found("redirect url not found")

      {:update_redirect_url, _} ->
        HttpUtils.bad_request("could not update redirect url")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:get_redirect_url, %RedirectUrl{} = redirect_url} <-
           {:get_redirect_url, RedirectUrls.get_redirect_url(id)},
         {:delete_redirect_url, {:ok, %RedirectUrl{}}} <-
           {:delete_redirect_url, RedirectUrls.delete_redirect_url(redirect_url)} do
      conn |> json(%{})
    else
      {:get_redirect_url, _} ->
        conn |> HttpUtils.not_found("redirect irl not found")

      {:delete_redirect_url, _} ->
        conn |> HttpUtils.bad_request("could not delete redirect url")
    end
  end
end
