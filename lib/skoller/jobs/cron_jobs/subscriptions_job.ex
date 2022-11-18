defmodule Skoller.CronJobs.SubscriptionsJob do
  require Logger

  alias Skoller.Schema.Subscription
  alias Skoller.Contexts.Subscriptions.Stripe.StripePurchases

  import Ecto.Query

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "subscriptions_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Subscriptions Job: " <> to_string(Time.utc_now))

    Subscription
    |> where([s], s.platform == :stripe)
    |> Skoller.Repo.all()
    |> update_stripe_subscriptions()

    Logger.info("Subscriptions Job Complete: " <> to_string(Time.utc_now))

  end

  defp update_stripe_subscriptions(subscriptions) do
    Enum.each(subscriptions, fn s ->
      if !is_nil(s.expiration_intent) && !is_nil(s.cancel_at_ms) do
        Logger.info("Subscription Job - checking cancel time against current time")
        if s.cancel_at_ms < :os.system_time(:seconds) && s.current_status == :active do
          Logger.info("Subscription Job - cancel time is less than current time, deactivating subscription.")
          s
          |> Subscription.changeset(%{current_status: :inactive})
          |> Skoller.Repo.update!()
        end
      end

      if is_nil(s.expiration_intent) && is_nil(s.cancel_at_ms) do
        Logger.info("Subscription Job - checking active subscription for changes.")
        with {:ok, %Stripe.Subscription{} = subscription} <- Stripe.Subscription.retrieve(s.transaction_id) do
          current_item = StripePurchases.get_current_item(subscription)

          s
          |> Subscription.changeset(
            %{
              current_status: current_item.current_status,
              expiration_intent: current_item.cancel_status,
              renew_status: :stripe_auto_renew_disabled,
              cancel_at_ms: subscription.cancel_at
            }
          )
          |> Skoller.Repo.update!()
        else
          _data -> nil
        end
      end
    end)
  end
end
