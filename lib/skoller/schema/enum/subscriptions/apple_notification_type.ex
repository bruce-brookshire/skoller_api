defmodule Skoller.Schema.Enum.Subscriptions.AppleNotificationType do
  defmacro __using__(_) do
    quote do
      @type(apple_notification_type ::
      :consumption_request,
      :did_change_renewal_pref,
      :did_change_renewal_status,
      :did_fail_to_renew,
      :did_renew,
      :expired,
      :grace_period_expired,
      :offer_redeemed,
      :price_increase,
      :refund,
      :refund_declined,
      :renewal_extended,
      :revoke,
      :subscribed,
      :test)
      @apple_notification_type_values [
        :consumption_request,
        :did_change_renewal_pref,
        :did_change_renewal_status,
        :did_fail_to_renew,
        :did_renew,
        :expired,
        :grace_period_expired,
        :offer_redeemed,
        :price_increase,
        :refund,
        :refund_declined,
        :renewal_extended,
        :revoke,
        :subscribed,
        :test
      ]
      @apple_notification_type_map %{
        "CONSUMPTION_REQUEST" => :consumption_request,
        "DID_CHANGE_RENEWAL_PREF" => :did_change_renewal_pref,
        "DID_CHANGE_RENEWAL_STATUS" => :did_change_renewal_status,
        "DID_FAIL_TO_RENEW" => :did_fail_to_renew,
        "DID_RENEW" => :did_renew,
        "EXPIRED" => :expired,
        "GRACE_PERIOD_EXPIRED" => :grace_period_expired,
        "OFFER_REDEEMED" => :offer_redeemed,
        "PRICE_INCREASE" => :price_increase,
        "REFUND" => :refund,
        "REFUND_DECLINED" => :refund_declined,
        "RENEWAL_EXTENDED" => :renewal_extended,
        "REVOKE" => :revoke,
        "SUBSCRIBED" => :subscribed,
        "TEST" => :test
      }
    end
  end
end
