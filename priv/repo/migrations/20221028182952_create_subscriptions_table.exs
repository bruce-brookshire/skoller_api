defmodule Skoller.Repo.Migrations.CreateSubscriptionsTable do
  use Ecto.Migration
  use Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType
  use Skoller.Schema.Enum.Subscriptions.ExpirationIntentType
  use Skoller.Schema.Enum.Subscriptions.AutoRenewType
  use Skoller.Schema.Enum.Subscriptions.BillingRetry
  use Skoller.Schema.Enum.Subscriptions.PaymentMethodType
  use Skoller.Schema.Enum.Subscriptions.CurrentSubscriptionStatus
  use Skoller.Schema.Enum.Subscriptions.RenewalIntervalType

  def change do
    execute(
      "CREATE TYPE platform AS ENUM (#{@platform_type_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE platform;"
    )

    execute(
      "CREATE TYPE expiration_intent AS ENUM (#{@expiration_intent_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE expiration_intent;"
    )

    execute(
      "CREATE TYPE auto_renew AS ENUM (#{@auto_renew_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE auto_renew;"
    )

    execute(
      "CREATE TYPE billing_retry AS ENUM (#{@billing_retry_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE billing_retry;"
    )

    execute(
      "CREATE TYPE payment_method AS ENUM (#{@payment_method_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE payment_method;"
    )

    execute(
      "CREATE TYPE current_subscription_status AS ENUM (#{@current_subscription_status_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE current_subscription_status;"
    )

    execute(
      "CREATE TYPE renewal_interval_type AS ENUM (#{@renewal_interval_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE renewal_interval_type;"
    )

    create table(:subscriptions) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:customer_id, :string)
      add(:transaction_id, :string)
      add(:payment_method, :payment_method)
      add(:platform, :platform, null: false)
      add(:expiration_intent, :expiration_intent, null: true)
      add(:auto_renew_status, :auto_renew, null: true)
      add(:billing_retry_status, :billing_retry, null: true)
      add(:current_status, :current_subscription_status)
      add(:current_status_unix_ts, :integer)
      add(:cancel_at_unix_ts, :integer)
      add(:renewal_interval, :renewal_interval_type)

      timestamps()
    end
  end
end
