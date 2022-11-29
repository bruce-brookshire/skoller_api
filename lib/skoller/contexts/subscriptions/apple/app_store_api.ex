defmodule Skoller.Contexts.Subscriptions.Apple.AppStoreApi do

  def get_subscription_info_by_transaction_id(transaction_id) do
    token = get_signed_token()
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <- HTTPoison.get(
      Application.fetch_env!(:skoller, :apple_app_store_connect_api) <> "/subscriptions/#{transaction_id}",
        [{"Content-Type", "application/json"}, {"Accept", "application/json"}, {"Authorization", "Bearer #{token}"}]
      ),
      {:ok, %{} = parsed_body} <- Jason.decode!(body) do
        {:ok, parsed_body}
      end
      |> IO.inspect

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
  def compile_jwt_payload() do
    %{
      "iss" => Application.fetch_env!(:skoller, :apple_issuer_id),
      "iat" => DateTime.utc_now() |> Timex.to_unix(),
      "exp" => DateTime.utc_now() |> DateTime.to_naive() |> Timex.shift(minutes: 1) |> Timex.to_unix(),
      "aud" => "appstoreconnect-v1",
      "bid" => Application.fetch_env!(:skoller, :apple_bundle_id)
    }
  end

  @spec create_signed_jwt(JOSE.JWK.t(), map(), map()) :: String.t()
  def create_signed_jwt(jwk, jws, jwt) do
    JOSE.JWT.sign(jwk, jws, jwt)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
