import Config

config :skoller,
  apple_receipt_verification_url: System.get_env("APPLE_RECEIPT_VERIFICATION_URL_TEST"),
  apple_app_store_connect_api: System.get_env("APPLE_APP_STORE_CONNECT_API_TEST"),
  apple_app_store_connect_key: System.get_env("APPLE_APP_STORE_CONNECT_STAGING_PRIVATE_KEY"),
  apple_app_store_connect_key_id: System.get_env("APPLE_APP_STORE_CONNECT_STAGING_KEY_ID")

config :stripity_stripe,
  hackney_opts: [{:connect_timeout, 1_000_000}, {:recv_timeout, 5_000_000}],
  api_key: System.get_env("STRIPE_API_TEST_SK")

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :skoller, SkollerWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

  config :cors_plug,
  origin: ["*"],
  max_age: 86_400,
  allow_headers: ["accept", "content-type", "authorization"],
  methods: ["GET", "DELETE", "PUT", "POST", "OPTIONS"],
  send_preflight_response?: true

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"#, level: :info

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :skoller, Skoller.Repo,
  username: "postgres",
  password: "postgres",
  database: "skoller_dev",
  hostname: "postgres",
  pool_size: 10,
  timeout: 200_000

# Configure Guardian Token Generation
config :skoller, Skoller.Auth,
  issuer: "Skoller",
  secret_key: "8noIgHlW3FlDPH8qM/jHzuOpbvidwx5cdg2RYrm08U2/eCBsGvEoD/vpi2DNCFPg"
