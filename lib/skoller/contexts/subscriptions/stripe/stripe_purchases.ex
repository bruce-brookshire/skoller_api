defmodule Skoller.Contexts.Subscriptions.Stripe.StripePurchases do
  @moduledoc false

  use Skoller.Schema.Enum.Subscriptions.PaymentMethodType

  alias Skoller.Schema.Subscription
  alias Skoller.Contexts.Subscriptions, as: SubscriptionsContext
  alias Skoller.Users.Trial

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
      created_at_ms: current_item.created,
      expiration_intent: current_item.cancel_status,
      auto_renew_status: current_item.renew_status,
      renewal_interval: current_item.renewal_interval
    })
    |> Skoller.Repo.insert!()
    |> case do
      %Skoller.Schema.Subscription{} = subscription ->
        Trial.expire(user_id)
        {:ok, subscription}
      %Ecto.Changeset{} = changeset ->
        {:error, changeset}
    end
  end

  @spec update_stripe_subscription(Skoller.Schema.Subscription.t(), Stripe.Subscription.t()) :: Subscription.t()
  def update_stripe_subscription(existing_subscription, %{subscription: new_subscription}) do
    current_item = get_current_item(new_subscription)

    existing_subscription
    |> Skoller.Schema.Subscription.changeset(
      %{
        cancel_at_ms: nil,
        transaction_id: new_subscription.id,
        current_status: current_item.current_status,
        created_at_ms: current_item.created,
        expiration_intent: current_item.cancel_status,
        auto_renew_status: current_item.renew_status,
        renewal_interval: current_item.renewal_interval
      }
    )
    |> Skoller.Repo.update!()
  end

  @spec cancel_stripe_subscription(Stripe.Subscription.t()) :: Subscription.t()
  def cancel_stripe_subscription(%Stripe.Subscription{} = subscription) do
    SubscriptionsContext.get_subscription_by_customer_id(subscription.customer)
    |> Subscription.changeset(
      %{
        expiration_intent: map_cancel_status(subscription),
        cancel_at_ms: subscription.cancel_at,
        auto_renew_status: :stripe_auto_renew_disabled,
        renewal_interval: nil
      }
    )
    |> Skoller.Repo.update!()
  end

  @spec get_current_item(map()) :: map() | nil
  def get_current_item([]) do
    nil
  end

  def get_current_item(%{items: %{data: data}} = subscription) do
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

  @spec map_renew_status(%{cancel_at_period_end: boolean()}) ::
    :stripe_will_renew | :stripe_auto_renew_disabled
  defp map_renew_status(%{cancel_at_period_end: cancel_at_period_end}) do
    case cancel_at_period_end do
      false -> :stripe_will_renew
      true -> :stripe_auto_renew_disabled
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
