defmodule Skoller.Contexts.Subscriptions.Stripe.StripePurchases do
  @moduledoc false

  use Skoller.Schema.Enum.Subscriptions.PaymentMethodType

  alias Skoller.Schema.Subscription
  alias Skoller.Contexts.Subscriptions, as: SubscriptionsContext

  @spec get_subscription_by_user_id(integer()) :: Subscription.t()
  def get_subscription_by_user_id(user_id) do
    Skoller.Repo.get(Subscription, user_id)
  end

  @spec create_stripe_subscription(
    %{
      subscription: map(),
      payment_method: payment_method_type(),
      user_id: integer(),
    }) :: Subscription.t()
  def create_stripe_subscription(
    %{
      subscription: %{subscription: subscription},
      payment_method: payment_method,
      user_id: user_id}) do

    current_item = get_current_item(subscription)

    %Subscription{}
    |> Subscription.changeset(%{
      platform: :stripe,
      payment_method: payment_method,
      user_id: user_id,
      customer_id: subscription.customer,
      transaction_id: subscription.id,
      current_status: current_item.current_status,
      current_status_unix_ts: current_item.created,
      expiration_intent: current_item.cancel_status,
      auto_renew_status: current_item.renew_status,
      renewal_interval: current_item.renewal_interval
    })
    |> Skoller.Repo.insert!()
  end

  @spec cancel_stripe_subscription(Stripe.Subscription.t()) :: Subscription.t()
  def cancel_stripe_subscription(%Stripe.Subscription{} = subscription) do
    SubscriptionsContext.get_subscription_by_customer_id(subscription.customer)
    |> Subscription.changeset(
      %{
        expiration_intent: map_cancel_status(subscription),
        cancel_at_unix_ts: subscription.cancel_at,
        auto_renew_status: :stripe_auto_renew_disabled,
        renewal_interval: nil
      }
    )
    |> Skoller.Repo.update!()
  end

  @spec get_current_item(map()) :: map()
  defp get_current_item(%{items: %{data: data}} = subscription) do
    data
    |> Enum.sort_by(& &1.created, :desc)
    |> List.first()
    |> then(fn recent_item ->
      %{
        created: subscription.created,
        current_status: map_status(recent_item.plan.active),
        renew_status: map_renew_status(subscription),
        cancel_status: map_cancel_status(subscription),
        renewal_interval: map_renewal_interval(recent_item.plan)
      }
    end)
  end

  @spec map_status(boolean()) :: :active | :inactive
  defp map_status(status) do
    case status do
      true -> :active
      false -> :inactive
    end
  end

  @spec map_renew_status(%{collection_method: String.t()}) ::
    :stripe_will_renew | :stripe_auto_renew_disabled
  defp map_renew_status(%{collection_method: collection_method}) do
    case collection_method do
      "charge_automatically" -> :stripe_will_renew
      _ -> :stripe_auto_renew_disabled
    end
  end

  @spec map_cancel_status(%{cancel_at_period_end: boolean()}) ::
    :stripe_cancelled | nil
  defp map_cancel_status(%{cancel_at_period_end: cancel_at_period_end}) do
    case cancel_at_period_end do
      true -> :stripe_cancelled
      _ -> nil
    end
  end

  defp map_renewal_interval(%{interval: interval}) do
    String.to_existing_atom(interval)
  end
end
