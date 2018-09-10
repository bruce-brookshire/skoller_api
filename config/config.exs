# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :skoller,
  ecto_repos: [Skoller.Repo]

# Configures the endpoint
config :skoller, SkollerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MoERdAtL9LkdMJHFVJolqyZr6rLHxHDMyKnbEl3Sag054kzU0xhRICcooJNLE+Ie",
  render_errors: [view: SkollerWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Skoller.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# This is for file uploads.
config :arc,
  storage: Arc.Storage.S3,
  bucket: {:system, "AWS_S3_BUCKET"}

#this is for AWS access
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

#this is for texting
config :ex_twilio, 
  account_sid: {:system, "TWILIO_ACCT_SID"},
  auth_token: {:system, "TWILIO_AUTH"}

#this is for apple notifications
config :pigeon, :apns,
  apns_default: %{
    cert: {:skoller, "apns/cert.pem"},
    key: {:skoller, "apns/key_unencrypted.pem"},
    mode: :dev
  }

config :pigeon, :fcm,
  fcm_default: %{
    key: System.get_env("FCM_KEY")
  }

#this is for local email
config :skoller, Skoller.Mailer,
  adapter: Bamboo.LocalAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
