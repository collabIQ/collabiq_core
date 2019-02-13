use Mix.Config

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("TEST_DB_USERNAME"),
  password: System.get_env("TEST_DB_PASSWORD"),
  database: System.get_env("TEST_DB"),
  hostname: System.get_env("TEST_DB_HOST"),
  pool: Ecto.Adapters.SQL.Sandbox
