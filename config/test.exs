use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :classnavapi, ClassnavapiWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :classnavapi, Classnavapi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "classnavapi_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Configure Guardian Token Generation
config :classnavapi, Classnavapi.Auth,
            issuer: "Classnavapi",
            secret_key: "8noIgHlW3FlDPH8qM/jHzuOpbvidwx5cdg2RYrm08U2/eCBsGvEoD/vpi2DNCFPg"
