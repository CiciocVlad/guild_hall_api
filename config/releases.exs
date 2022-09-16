import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :guild_hall, GuildHall.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :guild_hall, GuildHallWeb.Endpoint,
  load_from_system_env: true,
  url: [host: System.fetch_env!("GUILD_HALL_URL"), port: 80],
  http: [
    port: 80,
    transport_options: [socket_opts: [:inet6]]
  ],
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.fetch_env!("GUILD_HALL_SSL_KEY_PATH"),
    certfile: System.fetch_env!("GUILD_HALL_SSL_CERT_PATH"),
    cacertfile: System.fetch_env!("GUILD_HALL_SSL_CA_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"
