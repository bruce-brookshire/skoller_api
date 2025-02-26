defmodule Skoller.Contexts.Subscriptions.Apple.Schema.Notification.Response do

  use Ecto.Schema
  use Skoller.Schema.Enum.Subscriptions.AppleNotificationSubtype
  use Skoller.Schema.Enum.Subscriptions.AppleNotificationType

  require Logger

  alias Skoller.Contexts.Subscriptions.Apple.Schema.Notification.Data
  alias Skoller.Contexts.Subscriptions.Apple.InAppPurchases

  @type t :: %__MODULE__{
    notificationType: String.t(),
    subtype: String.t(),
    signedDate: integer(),
    version: String.t()
  }

  @primary_key false
  embedded_schema do
    embeds_one(:data, Data)
    field(:notificationType, :string)
    field(:notificationUUID, :string)
    field(:subtype, :string)
    field(:signedDate, :integer)
    field(:version, :string)
  end


  def get_signed_renewal_info(%{data: %{signedRenewalInfo: nil}}), do: nil
  def get_signed_renewal_info(%{data: %{signedRenewalInfo: renewal_info}}) do
    renewal_info
    |> JOSE.JWT.peek_payload()
    |> Map.get(:fields)
  end

  def get_signed_transaction_info(%{data: %{signedTransactionInfo: nil}}), do: nil
  def get_signed_transaction_info(%{data: %{signedTransactionInfo: signed_transaction}}) do
    signed_transaction
    |> JOSE.JWT.peek_payload()
    |> Map.get(:fields)
  end

  def handle_notification_type("DID_CHANGE_RENEWAL_STATUS", resp) do
    handle_subtype(resp.subtype, resp)
  end

  def handle_notification_type("DID_FAIL_TO_RENEW", resp) do
    IO.inspect("DID_FAIL_TO_RENEW - #{inspect(resp)}")
  end

  def handle_notification_type("DID_RENEW", resp) do
    handle_subtype(resp.subtype, resp)
  end

  def handle_notification_type("EXPIRED", resp) do
    transaction_info = get_signed_transaction_info(resp)
    subscription = Skoller.Repo.get_by(Skoller.Schema.Subscription, %{transaction_id: transaction_info["originalTransactionId"]})
    if !is_nil(subscription) do
      Logger.info("Expiring subscription for transaction: #{inspect(transaction_info["originalTransactionId"])} for user: #{inspect(subscription.user_id)}")
      InAppPurchases.expire_subscription(subscription)
    else
      Logger.error("Unable to find subscription for transaction_id: #{inspect(transaction_info["originalTransactionId"])}")
    end
  end

  def handle_notification_type("PRICE_INCREASE", resp) do
    IO.inspect("PRICE_INCREASE - #{inspect(resp)}")
  end

  def handle_notification_type("SUBSCRIBED", resp) do
    handle_subtype(resp.subtype, resp)
  end

  def handle_notification_type(_type, _resp), do: nil

  defp handle_subtype("AUTO_RENEW_DISABLED", resp) do
    renewal_info = get_signed_renewal_info(resp)
    transaction_info = get_signed_transaction_info(resp)
    subscription = Skoller.Repo.get_by(Skoller.Schema.Subscription, %{transaction_id: transaction_info["originalTransactionId"]})
    if !is_nil(subscription) do
      Logger.info("Cancelling subscription for transaction: #{inspect(transaction_info["originalTransactionId"])} for user: #{inspect(subscription.user_id)}")
      InAppPurchases.cancel_subscription(subscription, transaction_info, renewal_info)
    else
      Logger.error("Unable to find subscription for transaction_id: #{inspect(transaction_info["originalTransactionId"])}")
    end
  end

  defp handle_subtype("RESUBSCRIBE", resp) do
    IO.puts "SUBSCRIBED/RESUBSCRIBE"
    IO.inspect(resp.data.signedRenewalInfo, label: "renewalInfo")
    IO.inspect(resp.data.signedTransactionInfo, label: "transactionInfo")
    renewal_info = get_signed_renewal_info(resp)
    transaction_info = get_signed_transaction_info(resp)
    IO.inspect(renewal_info, label: "morphed renewal info")
    IO.inspect(transaction_info, label: "morphed transaction info")
  end

  defp handle_subtype("BILLING_RECOVERY", resp) do
    IO.puts "DID_RENEW/BILLING_RECOVERY"
    IO.inspect(resp.data.signedRenewalInfo, label: "renewalInfo")
    IO.inspect(resp.data.signedTransactionInfo, label: "transactionInfo")
    renewal_info = get_signed_renewal_info(resp)
    transaction_info = get_signed_transaction_info(resp)
    IO.inspect(renewal_info, label: "morphed renewal info")
    IO.inspect(transaction_info, label: "morphed transaction info")
  end

  defp handle_subtype(nil, resp) do
    IO.puts "DID_RENEW/nil"
    IO.inspect(resp.data.signedRenewalInfo, label: "renewalInfo")
    IO.inspect(resp.data.signedTransactionInfo, label: "transactionInfo")
    renewal_info = get_signed_renewal_info(resp)
    transaction_info = get_signed_transaction_info(resp)
    IO.inspect(renewal_info, label: "morphed renewal info")
    IO.inspect(transaction_info, label: "morphed transaction info")
  end
end
