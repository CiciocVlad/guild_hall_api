defmodule GuildHall.Repo.Migrations.UpdateDBStructure do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:attributes) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:roles) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:categories) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:pto) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:projects) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :description, :text
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:users_projects) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :user_impact, :text
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:redirect_urls) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end

    alter table(:user_attribute) do
      modify :id, :uuid, default: Ecto.UUID.generate()
      modify :inserted_at, :naive_datetime, default: fragment("now()")
      modify :updated_at, :naive_datetime, default: fragment("now()")
    end
  end
end
