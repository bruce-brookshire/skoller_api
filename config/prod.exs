use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# SkollerWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :skoller, SkollerWeb.Endpoint,
  load_from_system_env: true,
  url: [scheme: "https", host: "classnav-api-staging.herokuapp.com", port: 443]

# Do not print debug messages in production
config :logger, level: System.get_env("LOG_LEVEL") |> String.to_atom()

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :skoller, SkollerWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :skoller, SkollerWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :skoller, SkollerWeb.Endpoint, server: true
#

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :skoller, SkollerWeb.Endpoint,
secret_key_base: System.get_env("API_SECRET_KEY")

# Configure your database
config :skoller, Skoller.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  timeout: 100_000,
  pool_timeout: 100_000

# Configure Guardian Token Generation (this is for auth tokens)
config :skoller, Skoller.Auth,
          issuer: System.get_env("API_TOKEN_ISSUER"),
          secret_key: System.get_env("API_TOKEN_KEY")

# This is for apple notifications
config :pigeon, :apns,
  apns_default: %{
    cert: System.get_env("APNS_CERT"),
    key: System.get_env("APNS_KEY"),
    mode: :prod,
    use_2197: true
  }

# This is for emails
config :skoller, Skoller.Services.Mailer,
  adapter: Bamboo.SesAdapter
