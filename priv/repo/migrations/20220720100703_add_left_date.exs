defmodule GuildHall.Repo.Migrations.AddLeftDate do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :left_date, :date
    end
  end
end
