defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Common.SignedRenewal do
  use Ecto.Schema

  @type t :: %__MODULE__{
    autoRenewProductId: String.t(),
    autoRenewStatus: integer(),
    environment: String.t(),
    expirationIntent: integer(),
    isInBillingRetryPeriod: boolean(),
    originalTransactionId: String.t(),
    productId: String.t(),
    recentSubscriptionStartDate: integer(),
    signedDate: integer()
  }

  @primary_key false
  embedded_schema do
    field(:autoRenewProductId, :string)
    field(:autoRenewStatus, :integer)
    field(:environment, :string)
    field(:expirationIntent, :integer)
    field(:isInBillingRetryPeriod, :boolean)
    field(:originalTransactionId, :string)
    field(:productId, :string)
    field(:recentSubscriptionStartDate, :integer)
    field(:signedDate, :integer)
  end
end
