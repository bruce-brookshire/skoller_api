defmodule Skoller.Repo.Migrations.CreateSubscriptionsTable do
  use Ecto.Migration
  use Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType
  use Skoller.Schema.Enum.Subscriptions.ExpirationIntentType
  use Skoller.Schema.Enum.Subscriptions.AutoRenewType
  use Skoller.Schema.Enum.Subscriptions.BillingRetry

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
    create table(:subscriptions) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:transaction_id, :string)
      add(:platform, :platform, null: false)
      add(:expiration_intent, :expiration_intent, null: true)
      add(:auto_renew_status, :auto_renew, null: true)
      add(:billing_retry_status, :billing_retry, null: true)

      timestamps()
    end
  end
end
