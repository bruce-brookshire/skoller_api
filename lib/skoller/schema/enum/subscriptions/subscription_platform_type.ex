defmodule Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType do
  defmacro __using__(_) do
    quote do
      @type(platform_type :: :stripe, :in_app)
      @platform_type_values [:stripe, :in_app]
      @platform_type_map %{
        "Stripe" => :stripe,
        "In-App" => :in_app
      }
    end
  end
end
