defmodule Skoller.Schema.Enum.Subscriptions.RenewalIntervalType do
  defmacro __using__(_) do
    quote do
      @type(renewal_interval_type ::
        :month |
        :year |
        :lifetime
      )
      @renewal_interval_values [
        :month,
        :year,
        :lifetime
      ]
    end
  end
end
