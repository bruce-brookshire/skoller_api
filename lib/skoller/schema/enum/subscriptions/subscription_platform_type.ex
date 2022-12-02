defmodule Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType do
  defmacro __using__(_) do
    quote do
      @type(platform_type :: :stripe, :ios, :play)
      @platform_type_values [:stripe, :ios, :play]
      @platform_type_map %{
        "Stripe" => :stripe,
        "iOS" => :ios,
        "Google Play" => :play
      }
    end
  end
end
