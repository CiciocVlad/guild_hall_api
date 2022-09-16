# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :guild_hall,
  ecto_repos: [GuildHall.Repo]

config :guild_hall, GuildHall.Repo, migration_primary_key: [name: :id, type: :uuid]

# Configures the endpoint
config :guild_hall, GuildHallWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "gubqQeVlKF7Q/U7Jxb/an9w0PkrcNA/OaeoLffXRI1w95xq8ZzLgirI0Khl3RlRH",
  render_errors: [view: GuildHallWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: GuildHall.PubSub,
  live_view: [signing_salt: "+X1yMovs"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :joken, default_signer: System.get_env("GUILD_HALL_JOKEN_SECRET")

config :goth, json: System.get_env("GUILD_HALL_SERVICE_ACCOUNT_CREDENTIALS")

config :guild_hall, time_to_live_sec: System.get_env("GUILD_HALL_URL_TIME_TO_LIVE_SEC")

config :guild_hall, base_url: System.get_env("GUILD_HALL_BASE_URL")

config :guild_hall, GuildHall.PTODays.PTOBackendGoogleCalendar,
  base_url: "https://www.googleapis.com/calendar/v3/calendars",
  calendars: %{
    pto: System.get_env("GUILD_HALL_TIME_OFF_ID"),
    bonus_pto: System.get_env("GUILD_HALL_TIME_OFF_BONUS_DAYS_ID"),
    extra: System.get_env("GUILD_HALL_TIME_OFF_ADD_DAYS_ID"),
    legal: "ro.romanian.official%23holiday%40group.v.calendar.google.com"
  },
  # local time zone, will be used to set calendar query boundaries
  time_zone: "Europe/Bucharest"

config :guild_hall, pto_backend: GuildHall.PTODays.PTOBackendGoogleCalendar

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
