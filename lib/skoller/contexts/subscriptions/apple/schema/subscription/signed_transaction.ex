defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.SignedTransaction do
  use Ecto.Schema

  @type t :: %__MODULE__{
    bundleId: String.t(),
    environment: String.t(),
    expiresDate: integer(),
    inAppOwnershipType: String.t(),
    originalPurchaseDate: integer(),
    originalTransactionId: String.t(),
    productId: String.t(),
    purchaseDate: integer(),
    quantity: integer(),
    signedDate: integer(),
    subscriptionGroupIdentifier: String.t(),
    transactionId: String.t()
  }

  @primary_key false
  embedded_schema do
    field(:bundleId, :string)
    field(:environment, :string)
    field(:expiresDate, :integer)
    field(:inAppOwnershipType, :string)
    field(:originalPurchaseDate, :integer)
    field(:originalTransactionId, :string)
    field(:productId, :string)
    field(:purchaseDate, :integer)
    field(:quantity, :integer)
    field(:signedDate, :integer)
    field(:subscriptionGroupIdentifier, :string)
    field(:transactionId, :string)
  end
end
