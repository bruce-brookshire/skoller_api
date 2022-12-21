defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Data do

  use Ecto.Schema

  alias Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Transaction

  @type t :: %__MODULE__{
    lastTransactions: list(Transaction.t())
  }

  @primary_key false
  embedded_schema do
    embeds_many(:lastTransactions, Transaction)
    field(:subscriptionGroupIdentifier, :string)
  end
end
