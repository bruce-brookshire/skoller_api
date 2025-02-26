# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :skoller,
  ecto_repos: [Skoller.Repo],
  env: config_env(),
  apple_in_app_purchase_secret: System.get_env("APPLE_PROD_IN_APP_PURCHASE_SECRET"),
  apple_receipt_verification_url: System.get_env("APPLE_RECEIPT_VERIFICATION_URL_LIVE"),
  apple_app_store_connect_api: System.get_env("APPLE_APP_STORE_CONNECT_API_LIVE"),
  apple_app_store_connect_key: System.get_env("APPLE_APP_STORE_CONNECT_PROD_PRIVATE_KEY"),
  apple_app_store_connect_key_id: System.get_env("APPLE_APP_STORE_CONNECT_PROD_KEY_ID"),
  apple_issuer_id: System.get_env("APPLE_APP_ISSUER_ID"),
  apple_bundle_id: System.get_env("APPLE_PROD_APP_BUNDLE_ID")

config :logger,
  truncate: :infinity

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  truncate: :infinity

# Configures the endpoint
config :skoller, SkollerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MoERdAtL9LkdMJHFVJolqyZr6rLHxHDMyKnbEl3Sag054kzU0xhRICcooJNLE+Ie",
  render_errors: [view: SkollerWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Skoller.PubSub

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
       api_key: System.get_env("STRIPE_API_LIVE_SK")

config :pigeon, :fcm,
  fcm_default: %{
    key: System.get_env("FCM_KEY")
  }

config :phoenix, :json_library, Poison

# Cron jobs
config :oban, Oban,
  repo: Skoller.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 3600},
    {Oban.Plugins.Cron,
     crontab: [
      {"@daily", Skoller.CronJobs.StudentsCountJob},
      {"@monthly", Skoller.CronJobs.StudentReferralsReportJob},
      {"*/10 * * * *", Skoller.CronJobs.AssignmentReminderJob},
      {"*/10 * * * *", Skoller.CronJobs.AssignmentCompletionJob},
      {"*/10 * * * *", Skoller.CronJobs.ClassLocksJob},
      {"*/5 * * * *", Skoller.CronJobs.ClassPeriodJob},
      {"*/5 * * * *", Skoller.CronJobs.ClassSetupJob},
      {"*/5 * * * *", Skoller.CronJobs.NoClassesJob},
      {"*/10 * * * *", Skoller.CronJobs.EmailManagerJob},
      {"*/5 * * * *", Skoller.CronJobs.AnalyticsJob},
      {"*/10 * * * *", Skoller.CronJobs.TrialJob},
      {"0 * * * *", Skoller.CronJobs.SubscriptionsJob}
     ]}
  ],
  queues: [
    long_workers: 5,
    short_workers: 10
  ]



# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
