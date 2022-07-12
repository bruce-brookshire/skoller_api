# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :skoller,
  ecto_repos: [Skoller.Repo]

# Configures the endpoint
config :skoller, SkollerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MoERdAtL9LkdMJHFVJolqyZr6rLHxHDMyKnbEl3Sag054kzU0xhRICcooJNLE+Ie",
  render_errors: [view: SkollerWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Skoller.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# This is for file uploads.
config :arc,
  storage: Arc.Storage.S3,
  bucket: {:system, "AWS_S3_BUCKET"}

# Configuration for simplified MVC+S module declarations
config :ex_mvc,
  repo: Skoller.Repo,
  web_namespace: SkollerWeb

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

config :stripity_stripe,
       hackney_opts: [{:connect_timeout, 1_000_000}, {:recv_timeout, 5_000_000}],
       api_key: "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"

config :pigeon, :fcm,
  fcm_default: %{
    key: System.get_env("FCM_KEY")
  }

config :phoenix, :json_library, Poison

config :oban, Oban,
  repo: Skoller.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 3600},
    {Oban.Plugins.Cron,
     crontab: [
      #  {"@daily", Jobs.RefreshItems},
      #  {"@reboot", Jobs.RefreshItems},
      #  {"@daily", Jobs.Rewards.ConsumerConsumerReferralRewards},
      #  {"@reboot", Jobs.Rewards.ConsumerConsumerReferralRewards},
      #  {"@daily", Jobs.Rewards.ConsumerBusinessReferralRewards},
      #  {"@reboot", Jobs.Rewards.ConsumerBusinessReferralRewards},
      #  {"@daily", Jobs.TriggerBillingStatements},
      #  {"@daily", Jobs.TriggerSijomeAccountStatements}
     ]}
  ],
  queues: [
    default: 5
  ]



# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
