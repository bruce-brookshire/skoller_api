defmodule Skoller.Schema.Enum.Subscriptions.PaymentMethodType do
  defmacro __using__(_) do
    quote do
      @type(payment_method_type :: :card, :in_app, :other)
      @payment_method_values [:card, :in_app, :other]
      @payment_method_map %{
        "Card" => :card,
        "In App" => :in_app,
        "Other" => :other
      }
    end
  end
end
