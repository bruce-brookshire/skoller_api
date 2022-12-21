defmodule Skoller.Schema.Enum.Subscriptions.ExpirationIntentType do
  defmacro __using__(_) do
    quote do
      @type(expiration_intent_type ::
        :apple_cancelled,
        :apple_billing_error,
        :apple_non_consent_price_increase,
        :apple_product_not_available,
        :apple_other,
        :stripe_cancelled
      )
      @expiration_intent_values [
        :apple_cancelled,
        :apple_billing_error,
        :apple_non_consent_price_increase,
        :apple_product_not_available,
        :apple_other,
        :stripe_cancelled
      ]
      @expiration_intent_map %{
        "1" => %{
          value: :apple_cancelled,
          verbage: "The customer canceled their subscription."
        },
        "2" => %{
          value: :apple_billing_error,
          verbage: "Billing error; for example, the customer’s payment information is no longer valid."
        },
        "3" => %{
          value: :apple_non_consent_price_increase,
          verbage: "The customer didn’t consent to an auto-renewable subscription price increase that requires customer consent, allowing the subscription to expire."
        },
        "4" => %{
          value: :apple_product_not_available,
          verbage: "The product wasn’t available for purchase at the time of renewal."
        },
        "8" => %{
          value: :apple_other,
          verbage: "The subscription expired for some other reason."
        },
        "Stripe Cancelled" => %{
          value: :stripe_cancelled,
          verbage: "User cancelled their stripe subscription."
        }
      }
    end
  end
end
