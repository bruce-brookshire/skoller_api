defmodule Skoller.Schema.Enum.Subscriptions.CurrentSubscriptionStatus do
  defmacro __using__(_) do
    quote do
      @type(current_subscription_status_type ::
        :active,
        :inactive
      )
      @current_subscription_status_values [
        :active,
        :inactive
      ]
    end
  end
end
