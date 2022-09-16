defmodule GuildHall.RedirectUrls do
  @moduledoc """
  The RedirectUrls context.
  """

  import Ecto.Query, warn: false

  alias GuildHall.Repo
  alias GuildHall.RedirectUrls.RedirectUrl
  alias GuildHallWeb.RedirectUrlUtils

  def list_redirect_urls do
    Repo.all(RedirectUrl)
  end

  def get_redirect_url!(id), do: Repo.get!(RedirectUrl, id)

  def get_redirect_url(id), do: Repo.get(RedirectUrl, id)

  def get_by_random_string(random_string) do
    string = "#{Application.fetch_env!(:guild_hall, :base_url)}/#{random_string}"

    from(
      r in RedirectUrl,
      where: r.mapping == ^string
    )
    |> Repo.one()
  end

  def create_redirect_url(attrs \\ %{}) do
    mapping =
      "#{Application.fetch_env!(:guild_hall, :base_url)}/#{RedirectUrlUtils.random_string(8)}"

    %RedirectUrl{}
    |> RedirectUrl.changeset(attrs)
    |> Ecto.Changeset.force_change(
      :expires_at,
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.add(
        String.to_integer(Application.fetch_env!(:guild_hall, :time_to_live_sec)),
        :seconds
      )
    )
    |> Ecto.Changeset.force_change(:mapping, mapping)
    |> Repo.insert()
  end

  def update_redirect_url(%RedirectUrl{} = redirect_url, attrs) do
    redirect_url
    |> RedirectUrl.changeset(attrs)
    |> Repo.update()
  end

  def delete_redirect_url(%RedirectUrl{} = redirect_url) do
    Repo.delete(redirect_url)
  end

  def change_redirect_url(%RedirectUrl{} = redirect_url, attrs \\ %{}) do
    RedirectUrl.changeset(redirect_url, attrs)
  end
end
