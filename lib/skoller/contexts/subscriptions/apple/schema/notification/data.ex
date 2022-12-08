defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Notification.Data do
  use Ecto.Schema

  alias Skoller.Contexts.Subscriptions.Apple.Schema.Common.SignedTransaction
  alias Skoller.Contexts.Subscriptions.Apple.Schema.Common.SignedRenewal

  @type t :: %__MODULE__{
    bundleId: String.t(),
    environment: String.t()
  }

  @primary_key false
  embedded_schema do
    field(:bundleId, :string)
    field(:environment, :string)
    field(:signedRenewalInfo, :string)
    field(:signedTransactionInfo, :string)
  end
end
