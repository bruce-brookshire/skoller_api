defmodule Skoller.Contexts.Subscriptions.Apple.InAppPurchases do
  @moduledoc false

  require Logger

  use Skoller.Schema.Enum.Subscriptions.ExpirationIntentType
  use Skoller.Schema.Enum.Subscriptions.AutoRenewType

  alias Skoller.Schema.Subscription
  alias Skoller.Contexts.Subscriptions, as: SubscriptionContext

  @spec verify_receipt(String.t()) :: any()
  def verify_receipt(serverVerificationData) do
    HTTPoison.post(
      Application.fetch_env!(:skoller, :apple_receipt_verification_url),
      compile_payload(serverVerificationData),
      [{"Content-Type", "application/json"}]
    )
    |> handle_results()
  end

  @spec compile_payload(String.t()) :: map()
  defp compile_payload(verificationData) do
    %{
      "receipt-data" => verificationData,
      "password" => Application.fetch_env!(:skoller, :apple_in_app_purchase_secret),
      "exclude-old-transactions" => true
    } |> Jason.encode!()
  end

  @spec handle_results({:ok, %{status_code: integer(), body: map()}}) ::
    {:error, {:error, map()}} | {:ok, map()} | {:error, nil}
  defp handle_results({:ok, %{status_code: 200, body: body}}) do
    case handle_status(Jason.decode!(body)) do
      {:ok, data} -> {:ok, data}
      {:error, resp} -> {:error, resp}
      nil ->
        Logger.error("Received nil from handle_status/1")
        {:error, nil}
    end
  end

  @spec create_update_subscription(%{latest_receipt: list(), renewal_info: list()}, integer()) ::
    {:ok, Subscription.t()} | {:error, Ecto.Changeset.t()}
  def create_update_subscription(%{latest_receipt: latest_receipt, renewal_info: renewal_info}, user_id) do
    case SubscriptionContext.get_subscription_by_user_id(user_id) do
      %Subscription{} = subscription ->
        case update_subscription(subscription, latest_receipt, renewal_info) do
          {:ok, %Subscription{} = subscription} -> {:ok, subscription}
          {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
        end
      nil ->
        case create_subscription(user_id, latest_receipt, renewal_info) do
          {:ok, %Subscription{}} = subscription -> subscription
          {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
        end
    end
  end

  @spec create_subscription(integer(), list(), list()) ::
    {:ok, Subscription.t()} | {:error, Ecto.Changeset.t()}
  defp create_subscription(user_id, latest_receipt, renewal_info) do
    Logger.info("Creating IAP subscription for user: #{user_id}")
    current_receipt = get_current_receipt(latest_receipt)
    current_renewal_info = List.first(renewal_info)

    interval = map_interval(Map.get(current_receipt, "product_id", :nil))
    created_at = Map.get(current_receipt, "original_purchase_date_ms", nil)
    expiration_intent = map_expiration_intent(Map.get(current_renewal_info, "expiration_intent", nil), interval)

    %Subscription{}
    |> Subscription.changeset(%{
      platform: :ios,
      user_id: user_id,
      transaction_id: Map.get(current_receipt, "transaction_id", nil),
      created_at_ms: created_at,
      renewal_interval: interval,
      payment_method: :in_app,
      expiration_intent: expiration_intent,
      auto_renew_status: map_auto_renew(Map.get(current_renewal_info, "auto_renew_status", :error)),
      cancel_at_ms: get_cancel_at_for_creation(created_at, interval, expiration_intent),
      current_status: :active
    })
    |> Skoller.Repo.insert()
  end

  @spec update_subscription(Subscription.t(), list(), list()) ::
    {:ok, Subscription.t()} | {:error, Ecto.Changeset.t()}
  defp update_subscription(subscription, latest_receipt, renewal_info) do
    Logger.info("Updating IAP subscription for user: #{subscription.user_id}")
    Logger.info("subscription: #{inspect(subscription)}")
    Logger.info("latest_receipt #{inspect(latest_receipt)}")
    Logger.info("renewal_info #{inspect(renewal_info)}")
    current_receipt = get_current_receipt(latest_receipt)
    current_renewal_info = List.first(renewal_info)

    interval = map_interval(Map.get(current_receipt, "product_id", :nil))
    |> IO.inspect()
    created_at = Map.get(current_receipt, "original_purchase_date_ms", nil)
    expiration_intent = map_expiration_intent(Map.get(current_renewal_info, "expiration_intent", nil), interval)

    subscription
    |> Subscription.changeset(%{
      transaction_id: Map.get(current_receipt, "transaction_id", nil),
      platform: :ios,
      created_at_ms: created_at,
      renewal_interval: interval,
      payment_method: :in_app,
      expiration_intent: expiration_intent,
      auto_renew_status: map_auto_renew(Map.get(current_renewal_info, "auto_renew_status", :error)),
      cancel_at_ms: get_cancel_at_for_creation(created_at, interval, expiration_intent),
      current_status: :active
    })
    |> Skoller.Repo.update()
  end

  @spec get_current_receipt(list()) :: map()
  defp get_current_receipt(latest_receipt) when is_list(latest_receipt) do
    latest_receipt
    |> Enum.sort_by(& &1["original_purchase_date_ms"], :desc)
    |> List.first()
  end

  defp get_current_receipt(latest_receipt), do: latest_receipt

  defp map_interval(nil), do: nil

  # TODO Different subscription names for prod/staging/dev
  # Make this cleaner
  defp map_interval(product_id) do
    case product_id do
      "monthly" -> :month
      "yearly" -> :year
      "lifetime" -> :lifetime
      "monthlyStaging" -> :month
      "annualStaging" -> :year
      "annualStaging2" -> :year
      "lifetimeStaging" -> :lifetime
    end
  end

  defp map_expiration_intent(:error, _interval), do: nil
  defp map_expiration_intent(_expiration_intent, :lifetime), do: nil
  defp map_expiration_intent(expiration_intent, _interval) do
    case Map.get(@expiration_intent_map, expiration_intent, :error) do
      :error -> :error
      map -> map.value
    end
  end

  defp map_auto_renew(:error), do: :error
  defp map_auto_renew(auto_renew) do
    case Map.get(@auto_renew_map, auto_renew, :error) do
      :error -> :error
      map -> map.value
    end
  end

  defp get_cancel_at_for_creation(nil, _interval, _expiration_intent), do: nil
  defp get_cancel_at_for_creation(_created_at, :lifetime, _expiration_intent), do: nil
  defp get_cancel_at_for_creation(created_at, :year, expiration_intent)
    when not is_nil(expiration_intent) do
    created_at
    |> convert_ms_time()
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
    |> Timex.shift(years: 1)
    |> Timex.to_unix()
    |> Kernel.*(1000)
  end

  defp get_cancel_at_for_creation(created_at, :month, expiration_intent)
    when not is_nil(expiration_intent) do
    created_at
    |> convert_ms_time()
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
    |> Timex.shift(months: 1)
    |> Timex.to_unix()
    |> Kernel.*(1000)
  end

  defp convert_ms_time(ms_time), when is_binary(ms_time), do: elem(Integer.parse(ms_time), 0)
  defp convert_ms_time(ms_time), when is_integer(ms_time), do: ms_time


  @spec handle_status(%{String.t() => integer()}) ::
    {:error, map()} | {:error, String.t()} | {:ok, map()}
  defp handle_status(%{"status" => 21000}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21000 - The App Store could not read the JSON object you provided.")

    {
      :error,
      %{
        status: 21000,
        culprit: "Apple",
        reason: 	"The App Store could not read the JSON object you provided."
      }
    }
  end

  defp handle_status(%{"status" => 21002}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21002 - 	The data in the receipt-data property was malformed or missing.")

    {
      :error,
      %{
        status: 21002,
        culprit: "Apple",
        reason: "The data in the receipt-data property was malformed or missing."
      }
    }
  end

  defp handle_status(%{"status" => 21003}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21003 - 	The receipt could not be authenticated.")

    {
      :error,
      %{
        status: 21003,
        culprit: "Apple",
        reason: "The receipt could not be authenticated.."
      }
    }
  end

  defp handle_status(%{"status" => 21004}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21004 - 	The shared secret you provided does not match the shared secret on file for your account.")

    {
      :error,
      %{
        status: 21004,
        culprit: "Apple",
        reason: "The shared secret you provided does not match the shared secret on file for your account."
      }
    }
  end

  defp handle_status(%{"status" => 21005}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21005 - The receipt server is not currently available.")

    {
      :error,
      %{
        status: 21005,
        culprit: "Apple",
        reason: "The receipt server is not currently available."
      }
    }
  end

  defp handle_status(%{"status" => 21006}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21005 - This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.")

    {
      :error,
      %{
        status: 21006,
        culprit: "Apple",
        reason: "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions."
      }
    }
  end

  defp handle_status(%{"status" => 21007}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21005 - This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.")

    {
      :error,
      %{
        status: 21007,
        culprit: "Apple",
        reason: "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
      }
    }
  end

  defp handle_status(%{"status" => 21008}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21005 - This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.")

    {
      :error,
      %{
        status: 21008,
        culprit: "Apple",
        reason: "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
      }
    }
  end

  defp handle_status(%{"status" => 21010}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: 21005 - This receipt could not be authorized. Treat this the same as if a purchase was never made.")

    {
      :error,
      %{
        status: 21010,
        culprit: "Apple",
        reason: "This receipt could not be authorized. Treat this the same as if a purchase was never made."
      }
    }
  end

  defp handle_status(%{"status" => 0} = response) do
    response
    |> then(fn resp ->
      IO.inspect(resp)
      latest_receipt = Map.get(resp, "latest_receipt_info", nil)
      renewal_info = Map.get(resp, "pending_renewal_info", nil)

      if is_nil(latest_receipt) || is_nil(renewal_info) do
        {:error, "Unable to process IAP receipt. latest_receipt is nil #{is_nil(latest_receipt)}. renewal_info is nil #{is_nil(renewal_info)}"}
      else
        {:ok, %{latest_receipt: latest_receipt, renewal_info: renewal_info}}
      end
    end)

  end

  defp handle_status(%{"status" => status}) do
    Logger.warn("In App Purchase - Verify receipt failed. Status Code: #{status} - Internal data access error")

    {
      :error,
      %{
        status: status,
        culprit: "Apple",
        reason: "Internal data access error. No further information available."
      }
    }
  end
end
