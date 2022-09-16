defmodule GuildHall.Repo.Migrations.MoreDBDefaults do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"")

    alter table(:articles) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))

      modify(:inserted_at, :naive_datetime, default: fragment("now()"))
      modify(:updated_at, :naive_datetime, default: fragment("now()"))
    end

    alter table(:best_of_quotes) do
      modify(:id, :uuid, default: fragment("gen_random_uuid()"))

      modify(:inserted_at, :naive_datetime, default: fragment("now()"))
      modify(:updated_at, :naive_datetime, default: fragment("now()"))
    end
  end
end
