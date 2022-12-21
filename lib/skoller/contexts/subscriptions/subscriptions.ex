defmodule Skoller.Contexts.Subscriptions do
  @moduledoc false
  alias Skoller.Schema.Subscription

  @spec get_subscription_by_user_id(String.t()) :: Subscription.t() | nil
  def get_subscription_by_user_id(user_id) do
    Skoller.Repo.get_by(Subscription, %{user_id: user_id})
  end

  @spec get_subscription_by_customer_id(String.t()) :: Subscription.t() | nil
  def get_subscription_by_customer_id(customer_id) do
    Skoller.Repo.get_by(Subscription, %{customer_id: customer_id})
  end
end
