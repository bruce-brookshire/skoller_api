defmodule Skoller.Schema.Enum.Subscriptions.AppleNotificationSubtype do
  defmacro __using__(_) do
    quote do
      @type(apple_notification_subtype ::
        :initial_buy,
        :resubscribe,
        :auto_renew_enabled,
        :auto_renew_disabled,
        :voluntary,
        :billing_retry,
        :price_increase,
        :product_not_for_sale,
        :grace_period,
        :pending,
        :accepted)
      @apple_notification_subtype_values [
        :initial_buy,
        :resubscribe,
        :auto_renew_enabled,
        :auto_renew_disabled,
        :voluntary,
        :billing_retry,
        :price_increase,
        :product_not_for_sale,
        :grace_period,
        :pending,
        :accepted
      ]
      @apple_notification_subtype_map %{
        "INITIAL_BUY" => :initial_buy,
        "RESUBSCRIBE" => :resubscribe,
        "AUTO_RENEW_ENABLED" => :auto_renew_enabled,
        "AUTO_RENEW_DISABLED" => :auto_renew_disabled,
        "VOLUNTARY" => :voluntary,
        "BILLING_RETRY" => :billing_retry,
        "PRICE_INCREASE" => :price_increase,
        "PRODUCT_NOT_FOR_SALE" => :product_not_for_sale,
        "GRACE_PERIOD" => :grace_period,
        "BILLING_RECOVERY" => :billing_recovery,
        "PENDING" => :pending,
        "ACCEPTED" => :accepted
      }
    end
  end
end
