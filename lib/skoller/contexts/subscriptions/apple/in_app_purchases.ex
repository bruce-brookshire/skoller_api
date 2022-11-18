defmodule Skoller.Contexts.Subscriptions.Apple.InAppPurchases do
  @moduledoc false

  require Logger

  @spec verify_receipt(String.t()) :: any()
  def verify_receipt(serverVerificationData) do
    HTTPoison.post(
      Application.fetch_env!(:skoller, :apple_receipt_verification_url),
      compile_payload(serverVerificationData),
      [{"Content-Type", "application/json"}]
    )
    |> handle_results()
  end

  defp compile_payload(verificationData) do
    %{
      "receipt-data" => verificationData,
      "password" => Application.fetch_env!(:skoller, :apple_in_app_purchase_secret),
      "exclude-old-transactions" => true
    } |> Jason.encode!()
  end

  defp handle_results({:ok, %{status_code: 200, body: body}}) do
    IO.inspect(Jason.decode!(body))
    case handle_status(Jason.decode!(body)) do
      {:error, resp} -> {:error, resp}
      {:ok, _} -> IO.inspect("hurray!")
      nil -> IO.puts "wtf?"
    end
  end

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
    renewal_info = Map.get(response, "pending_renewal_info", nil)
    |> then(fn info ->
      case info do
        nil -> nil
        # _ -> if is_list(renewal)
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
