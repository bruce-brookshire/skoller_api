use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :skoller, SkollerWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :skoller, Skoller.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "skoller_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Configure Guardian Token Generation
config :skoller, Skoller.Auth,
            issuer: "Skoller",
            secret_key: "8noIgHlW3FlDPH8qM/jHzuOpbvidwx5cdg2RYrm08U2/eCBsGvEoD/vpi2DNCFPg"
