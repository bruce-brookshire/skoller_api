defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Transaction do

  use Ecto.Schema

  @type t :: %__MODULE__{
    originalTransactionId: String.t(),
    status: integer(),
    signedTransactionInfo: String.t(),
    signedRenewalInfo: String.t()
  }

  @primary_key false
  embedded_schema do
    field(:originalTransactionId, :string)
    field(:status, :integer)
    field(:signedTransactionInfo, :string)
    field(:signedRenewalInfo, :string)
  end
end
