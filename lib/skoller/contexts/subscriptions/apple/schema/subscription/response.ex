defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Response do

  use Ecto.Schema

  require Logger

  alias Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Data
  alias Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.SignedTransaction
  alias Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.SignedRenewal

  @type t :: %__MODULE__{
    bundleId: String.t(),
    data: list(Data.t())
  }

  @primary_key false
  embedded_schema do
    field(:bundleId, :string)
    embeds_many(:data, Data)
  end

  @spec get_signed_renewal_info(__MODULE__.t()) :: String.t()
  def get_signed_renewal_info(resp) do
    List.first(resp.data)
    |> then(& List.first(&1.lastTransactions))
    |> then(& &1.signedRenewalInfo)
    |> JOSE.JWT.peek_payload()
    |> then(& EctoMorph.cast_to_struct(&1.fields, SignedRenewal))
    |> case do
      {:ok, %SignedRenewal{} = signed_renewal} -> signed_renewal
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to cast apple subscription response to SignedRenewal: #{inspect(changeset)}")
        nil
    end
  end

  @spec get_signed_transaction_info(__MODULE__.t()) :: String.t()
  def get_signed_transaction_info(resp) do
    List.first(resp.data)
    |> then(& List.first(&1.lastTransactions))
    |> then(& &1.signedTransactionInfo)
    |> JOSE.JWT.peek_payload()
    |> then(& EctoMorph.cast_to_struct(&1.fields, SignedTransaction))
    |> case do
      {:ok, %SignedTransaction{} = signed_transaction} -> signed_transaction
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to cast apple subscription response to SignedTransaction: #{inspect(changeset)}")
        nil
    end
  end
end
