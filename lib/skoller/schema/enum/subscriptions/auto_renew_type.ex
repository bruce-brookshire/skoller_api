defmodule Skoller.Schema.Enum.Subscriptions.AutoRenewType do
  defmacro __using__(_) do
    quote do
      @type(auto_renew_type :: :apple_will_renew, :apple_auto_rewnewal_disabled)
      @auto_renew_values [:apple_will_renew, :apple_auto_rewnewal_disabled]
      @auto_renew_map %{
        "0" => %{
          value: :apple_auto_rewnewal_disabled,
          verbage: "The customer has turned off automatic renewal for the subscription."
        },
        "2" => %{
          value: :apple_will_renew,
          verbage: "The subscription will renew at the end of the current subscription period."
        }
      }
    end
  end
end
