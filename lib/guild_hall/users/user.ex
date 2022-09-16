defmodule GuildHall.Users.User do
  use GuildHall.Schema
  import Ecto.Changeset
  alias GuildHall.Projects.Project
  alias GuildHall.Attributes.Attribute
  alias GuildHall.PTODays.PTO
  alias GuildHall.BestOfQuotes.Quote
  alias GuildHall.Articles.Article

  schema "users" do
    field :avatar, :string
    field :bio, :string
    field :email, :string
    field :hobbies, {:array, :string}
    field :job_title, :string
    field :joined_date, :date
    field :left_date, :date
    field :name, :string
    field :phone, :string
    field :preferred_name, :string
    field :social_media, :map
    field :is_admin, :boolean, default: false
    field :years_of_experience, :string, default: "0"
    field :number_of_industries, :string, default: "0"
    field :number_of_projects, :string, default: "0"
    many_to_many :projects, Project, join_through: "users_projects", on_replace: :delete
    many_to_many :attributes, Attribute, join_through: "user_attribute", on_replace: :delete
    has_many :pto, {"pto", PTO}
    has_many :quotes, {"best_of_quotes", Quote}
    has_many :articles, {"articles", Article}

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :preferred_name,
      :name,
      :job_title,
      :joined_date,
      :left_date,
      :bio,
      :phone,
      :hobbies,
      :avatar,
      :social_media,
      :is_admin,
      :years_of_experience,
      :number_of_industries,
      :number_of_projects
    ])
    |> validate_required([
      :email,
      :preferred_name,
      :name,
      :joined_date,
      :years_of_experience,
      :number_of_industries,
      :number_of_projects
    ])
    |> unique_constraint([:email], name: :unique_email)
  end
end
