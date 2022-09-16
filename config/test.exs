import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :guild_hall, GuildHall.Repo,
  username: "guild_hall",
  password: "guild_hall",
  database: "guild_hall_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :guild_hall, GuildHallWeb.Endpoint,
  http: [
    port: 4002
  ],
  server: false

config :joken, default_signer: "test secret"

# generated key, only used in tests
private_key =
  """
  -----BEGIN RSA PRIVATE KEY-----
  MIICWwIBAAKBgQC2BVy/cnHvR3Y4IqAV38uF8oN0SDGdyC2Nk/7UuSMwInk6A3xz
  ptGjznyjtyHFAns26FLsL/pp9TfrRqBmMEBbpKSHGsdEJzQ9/oXvbIcVJbsSsFO7
  c3xs6t0uDDL5FVL1LEUji7hfdU5LpEqJuOT6MllQPBo6IP58tTOHmRwQkQIDAQAB
  AoGAajLUu0ptmTrribMCDeEl4L/u3IBmmnU5xrnLW5etJR9n9WYlTWDOPbFy3R4z
  ELvy4cVI5E7V3s5Y0ufBG/4Y/aMh6Hic9iNnQGgHN7pSbkvJd73ITrfjyrnRHT4h
  S/kykvdz2uJmTa08J3pA2q55MHp0Kttxb9P3TXMg6a8ZFUECQQDeKPxmAKyLgYah
  mKXa6vTyzA9Sf6t7D1zsXWgqctls9n2dtj1zckUnGHIy9BzmzQM1C3QJq57btv/3
  4bbpZWGpAkEA0b8r6eREOaOnUdek0AAUSyvjVear3vDsvY0YhjtTcNrzEVB93TA+
  J3JqQTRT02L6FAsDqsmjRnahm0Je8YjYqQJAbSxbDI1cPZpDXPo01yYLhZ1+Eh6n
  WGwuUAF/BQ03h/KBvJUoEamgDhxXUm7gHRO2dcTRG0d5Y6PEmj4TsxKdMQJAN8by
  0pwVWI6grC8AcR/URblCF1HkWsEO88lVwDx+kABpqy0Qi4WMwci3YOedcxVbE4Fq
  VDyS4uYhS7x2qxyNIQJAccAJ7gGbng1+sZgM5eHlZikTks1WI+N2kJjtXNuhMo9S
  H9rh6OmQ3oUdn7KE5uPXXKxWv2bFx8rXoJlE1sO0Kg==
  -----END RSA PRIVATE KEY----
  """
  |> String.replace("\n", "\\n")

config :goth,
  json: """
  {
    "type": "service_account",
    "project_id": "crafting-guild-hall-dev",
    "private_key_id": "private-key-id",
    "private_key": "#{private_key}",
    "client_email": "client-email",
    "client_id": "client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/client-id"
  }
  """

config :guild_hall, time_to_live_sec: "100"

config :guild_hall, base_url: "http://localhost:4002/profile"

config :junit_formatter,
  report_file: "test-report.xml"

# Print only warnings and errors during test
config :logger, level: :warn
