use Mix.Config

config :core, Core.Security.Guardian,
  secret_key: System.get_env("PROD_KEY_BASE")

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PROD_DB_USERNAME"),
  password: System.get_env("PROD_DB_PASSWORD"),
  database: System.get_env("PROD_DB"),
  hostname: System.get_env("PROD_DB_HOST"),
  pool_size: 10
