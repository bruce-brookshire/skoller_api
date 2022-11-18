defmodule Skoller.Schema.Subscription do
  use Skoller.Schema
  use Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType
  use Skoller.Schema.Enum.Subscriptions.ExpirationIntentType
  use Skoller.Schema.Enum.Subscriptions.AutoRenewType
  use Skoller.Schema.Enum.Subscriptions.BillingRetry
  use Skoller.Schema.Enum.Subscriptions.PaymentMethodType
  use Skoller.Schema.Enum.Subscriptions.CurrentSubscriptionStatus
  use Skoller.Schema.Enum.Subscriptions.RenewalIntervalType

  alias Skoller.Users.User

  @type t :: %__MODULE__{
    user_id: integer(),
    customer_id: String.t(),
    transaction_id: String.t(),
    payment_method: payment_method_type(),
    platform: platform_type(),
    expiration_intent: expiration_intent_type(),
    auto_renew_status: auto_renew_type(),
    billing_retry_status: billing_retry_type(),
    current_status: current_subscription_status_type(),
    created_at_ms: integer(),
    cancel_at_ms: integer(),
    renewal_interval: renewal_interval_type()
  }

  schema "subscriptions" do
    field(:customer_id, :string)
    field(:transaction_id, :string)
    field(:payment_method, Ecto.Enum, values: @payment_method_values)
    field(:platform, Ecto.Enum, values: @platform_type_values)
    field(:expiration_intent, Ecto.Enum, values: @expiration_intent_values)
    field(:auto_renew_status, Ecto.Enum, values: @auto_renew_values)
    field(:billing_retry_status, Ecto.Enum, values: @billing_retry_values)
    field(:current_status, Ecto.Enum, values: @current_subscription_status_values)
    field(:created_at_ms, :integer)
    field(:cancel_at_ms, :integer)
    field(:renewal_interval, Ecto.Enum, values: @renewal_interval_values)

    belongs_to(:user, User)

    timestamps()
  end

  @required [
    :transaction_id,
    :payment_method,
    :platform,
    :user_id
  ]
  @optional [
    :expiration_intent,
    :auto_renew_status,
    :billing_retry_status,
    :customer_id,
    :current_status,
    :created_at_ms,
    :cancel_at_ms,
    :renewal_interval
  ]

  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
