defmodule Skoller.Schema.Enum.Subscriptions.BillingRetry do
  defmacro __using__(_) do
    quote do
      @type(billing_retry_type :: :apple_is_attempting_billing_retry, :apple_stopped_attempting_billing_retry)
      @billing_retry_values [:apple_is_attempting_billing_retry, :apple_stopped_attempting_billing_retry]
      @billing_retry_map %{
        "0" => %{
          value: :apple_stopped_attempting_billing_retry,
          verbage: "The App Store has stopped attempting to renew the subscription."
        },
        "1" => %{
          value: :apple_is_attempting_billing_retry,
          verbage: "The App Store is attempting to renew the subscription."
        }
      }
    end
  end
end
