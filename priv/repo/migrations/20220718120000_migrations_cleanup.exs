defmodule GuildHall.Repo.Migrations.Cleanup do
  @doc """
  This migration removes traces of previous migrations around skills - a table
  that is no longer used.
  """

  use Ecto.Migration

  def change do
    execute("""
    DELETE FROM schema_migrations
    WHERE version IN ('20210928120128', '20211013175524', '20220330144236', '20220330144314')
    """)
  end
end
