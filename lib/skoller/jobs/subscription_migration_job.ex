defmodule Skoller.Jobs.SubscriptionMigrationJob do

  alias Skoller.Payments.Stripe, as: Payment
  alias Skoller.Contexts.Subscriptions.Stripe.StripePurchases
  alias Skoller.Schema.Subscription

  def perform() do
    s = Skoller.Repo.all(Payment)

    Enum.each(s, fn s ->
      # No data ([]) means no subscriptions, discard from table.
      with {:ok, %Stripe.List{data: data}} <- Stripe.Subscription.list(%{customer: s.customer_id}) do
        if Enum.empty?(data) do
          s
          |> Skoller.Repo.delete!()
        else
          data =
            cond do
              is_list(data) && length(data) > 1 ->
                data
                |> Enum.sort_by(& &1.created, :desc)
              is_list(data) && length(data) == 1 ->
                List.first(data)
              !is_list(data) -> data
            end
            |> IO.inspect(label: "DATA")

            current_item = StripePurchases.get_current_item(data)
            |> IO.inspect()

          %Subscription{}
          |> Subscription.changeset(
            %{
              platform: :stripe,
              payment_method: :card,
              user_id: s.user_id,
              customer_id: s.customer_id,
              transaction_id: data.id,
              current_status: current_item.current_status,
              created_at_ms: current_item.created,
              expiration_intent: current_item.cancel_status,
              auto_renew_status: current_item.renew_status,
              renewal_interval: current_item.renewal_interval,
              cancel_at_ms: data.cancel_at
            }
          )
          |> Skoller.Repo.insert!()
        end
      else
        data -> IO.inspect(data, label: "Error")
      end
    end)
  end
end
