defmodule GuildHall.Repo.Migrations.IDsDefaultToRandomUUID do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"")

    alter table(:users) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:attributes) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:roles) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:categories) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:pto) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:projects) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:users_projects) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:redirect_urls) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end

    alter table(:user_attribute) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))
    end
  end
end
