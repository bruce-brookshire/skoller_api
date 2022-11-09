defmodule Skoller.Schema.Subscription do
  use Skoller.Schema
  use Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType
  use Skoller.Schema.Enum.Subscriptions.ExpirationIntentType
  use Skoller.Schema.Enum.Subscriptions.AutoRenewType
  use Skoller.Schema.Enum.Subscriptions.BillingRetry

  alias Skoller.Users.User

  @type t :: %__MODULE__{
    user_id: integer(),
    transaction_id: String.t(),
    platform: platform_type()
  }

  schema "subscriptions" do
    field(:transaction_id, :string)
    field(:platform, Ecto.Enum, values: @platform_type_values)
    field(:expiration_intent, Ecto.Enum, values: @expiration_intent_values)
    field(:auto_renew_status, Ecto.Enum, values: @auto_renew_values)
    field(:billing_retry_status, Ecto.Enum, values: @billing_retry_values)

    belongs_to(:user, User)

    timestamps()
  end

  @required [:transaction_id, :platform]
  @optional [:expiration_intent, :auto_renew_status, :billing_retry_status]

  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
