use Mix.Config

config :core, Core.Repo,
  username: System.get_env("DEV_DB_USERNAME"),
  password: System.get_env("DEV_DB_PASSWORD"),
  database: System.get_env("DEV_DB"),
  hostname: System.get_env("DEV_DB_HOST"),
  pool_size: 10
