defmodule GuildHall.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :preferred_name, :string
      add :name, :string
      add :job_title, :string
      add :joined_date, :date
      add :bio, :text
      add :phone, :string
      add :hobbies, {:array, :string}
      add :avatar, :string
      add :social_media, :map

      timestamps()
    end

    create(unique_index(:users, [:email], name: :unique_email))
  end
end
