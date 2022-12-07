defmodule Skoller.Contexts.Subscriptions.Apple.AppStoreApi do

  alias Skoller.Contexts.Subscriptions.Apple.Schema.Subscription.Response, as: SubscriptionResponse
  alias Skoller.Contexts.Subscriptions.Apple.Schema.Notification.Response, as: NotificationResponse

  require Logger

  def get_subscription_info_by_transaction_id(transaction_id) do
    case get_subscription_info(transaction_id) do
      %SubscriptionResponse{} = resp ->
        %{
          renewal_info: SubscriptionResponse.get_signed_renewal_info(resp),
          transaction_info: SubscriptionResponse.get_signed_transaction_info(resp)
        }
      {:error, %Ecto.Changeset{} = changeset} -> changeset
    end
  end

  def handle_webhook_notification(resp) do
      JOSE.JWT.peek_payload(resp)
      |> IO.inspect(label: "PEEKING PAYLOAD**********")
      |> Map.get(:fields)
      |> EctoMorph.cast_to_struct(NotificationResponse)
      |> elem(1)
      |> case do
        %NotificationResponse{} = resp -> NotificationResponse.handle_notification_type(resp.notificationType, resp)
        %Ecto.Changeset{} = changeset ->
          Logger.error("Unable to parse payload into a notification response in AppStoreApi.handle_webhook_notification/2. Changeset: #{changeset}")
          {:error, changeset}
      end
  end

  defp get_subscription_info(transaction_id) do
    token = get_signed_token()

    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <- HTTPoison.get(
      Application.fetch_env!(:skoller, :apple_app_store_connect_api) <> "/subscriptions/#{transaction_id}",
        [{"Content-Type", "application/json"}, {"Accept", "application/json"}, {"Authorization", "Bearer #{token}"}]
      ),
      resp <- Jason.decode!(body, keys: :atoms),
      {:ok, parsed_resp} <- EctoMorph.cast_to_struct(resp, SubscriptionResponse) do
        parsed_resp
      else
        result -> result
      end
      |> case do
        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error("Unable to cast subscription response to Subscription.Response: #{inspect(changeset)}")
          changeset
        resp -> resp
      end
  end

  defp get_signed_token() do
    create_signed_jwt(
      create_jwk(),
      create_jws(),
      compile_jwt_payload()
    )
  end

  @spec create_jwk() :: JOSE.JWK.t()
  defp create_jwk() do
    JOSE.JWK.from_pem(Application.fetch_env!(:skoller, :apple_app_store_connect_key))
  end

  @spec create_jws() :: map()
  defp create_jws() do
    %{
      "alg" => "ES256",
      "kid" => Application.fetch_env!(:skoller, :apple_app_store_connect_key_id),
      "typ" => "JWT"
    }
  end

  @spec compile_jwt_payload() :: map()
  defp compile_jwt_payload() do
    %{
      "iss" => Application.fetch_env!(:skoller, :apple_issuer_id),
      "iat" => DateTime.utc_now() |> Timex.to_unix(),
      "exp" => DateTime.utc_now() |> DateTime.to_naive() |> Timex.shift(minutes: 1) |> Timex.to_unix(),
      "aud" => "appstoreconnect-v1",
      "bid" => Application.fetch_env!(:skoller, :apple_bundle_id)
    }
  end

  @spec create_signed_jwt(JOSE.JWK.t(), map(), map()) :: String.t()
  defp create_signed_jwt(jwk, jws, jwt) do
    JOSE.JWT.sign(jwk, jws, jwt)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
