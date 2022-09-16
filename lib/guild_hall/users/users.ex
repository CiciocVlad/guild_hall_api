defmodule GuildHall.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias GuildHall.Repo
  alias GuildHall.Users.User
  alias GuildHall.Projects.Project
  alias GuildHall.RedirectUrls.RedirectUrl
  alias GuildHall.UsersProjects.UserProject

  def list_users do
    from(
      user in User,
      order_by: [not is_nil(user.left_date), user.name],
      preload: [:attributes]
    )
    |> Repo.all()
  end

  def get_by_email(email) do
    from(
      user in User,
      where: user.email == ^email
    )
    |> Repo.one()
  end

  def get_user_by_mapping(random_string) do
    mapping = "%/profile/#{random_string}"
    date = DateTime.utc_now()

    from(
      user in User,
      join: r in RedirectUrl,
      on: user.id == r.user_id,
      where: like(r.mapping, ^mapping) and r.expires_at > ^date,
      select: user
    )
    |> Repo.one()
  end

  def get_user!(id) do
    query =
      from(
        u in User,
        where: u.id == ^id,
        preload: [:projects, :attributes, :pto, :quotes, :articles]
      )

    try do
      Repo.one!(query)
    rescue
      Ecto.Query.CastError ->
        raise Ecto.NoResultsError, queryable: query
    end
  end

  def get_user(id) do
    try do
      Repo.get(User, id)
      |> Repo.preload([:projects, :attributes, :pto, :quotes, :articles])
    rescue
      Ecto.Query.CastError ->
        nil
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def get_roles(user_id) do
    from(
      up in UserProject,
      join: role in assoc(up, :role),
      where: up.user_id == ^user_id,
      group_by: role.title,
      select: role.title
    )
    |> Repo.all()
  end

  def get_attributes(user_id, category_name) do
    from(
      u in User,
      join: a in assoc(u, :attributes),
      join: c in assoc(a, :category),
      where: u.id == ^user_id,
      where: c.name == ^category_name,
      group_by: [a.id, a.name],
      order_by: a.name
    )
    # this is a rather long shot but seems to work
    # the order of the bindings is user, attribute, category, user_attribute
    |> select([_u, a, _c, ua], %{
      id: a.id,
      name: a.name,
      is_favorite: fragment("bool_or(?)", ua.is_favorite)
    })
    |> Repo.all()
  end

  def get_projects_of_user(user_id) do
    from(
      p in Project,
      join: up in UserProject,
      on: up.user_id == ^user_id and up.project_id == p.id,
      select: %{project: p, user_project: up}
    )
    |> Repo.all()
  end
end
