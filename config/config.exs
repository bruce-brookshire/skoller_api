# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :classnavapi,
  ecto_repos: [Classnavapi.Repo]

# Configures the endpoint
config :classnavapi, ClassnavapiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MoERdAtL9LkdMJHFVJolqyZr6rLHxHDMyKnbEl3Sag054kzU0xhRICcooJNLE+Ie",
  render_errors: [view: ClassnavapiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Classnavapi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :arc,
  storage: Arc.Storage.S3,
  bucket: {:system, "AWS_S3_BUCKET"}

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
