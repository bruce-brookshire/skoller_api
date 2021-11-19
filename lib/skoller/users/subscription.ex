defmodule Skoller.Users.Subscription do
  @moduledoc """
  The Users Subscription context.
  """

  alias Skoller.{Repo, Payments}
  alias Skoller.Users.{User, Trial}

  import Ecto.Query

  def create(conn, %{"payment_method" => %{"token" => token} = payment_method}) do
    with {:ok, %Stripe.Token{card:  %Stripe.Card{id: card_id}}} <- Stripe.Token.retrieve(token),
         {:ok, %User{} = user} <- conn.assigns |> Map.fetch(:user),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <- find_or_create_stripe_customer(
           token,
           user.id,
           nil
         ),
         {:ok, %Stripe.Subscription{}} <- create_subscription(
           customer_stripe_id,
           payment_method["plan_id"],
           user
         ) do
      create_or_update_card_info(
        %{
          user_id: user.id,
          customer_id: customer_stripe_id,
          payment_method: "card",
          card_info: %{card_id: card_id}
        }
      )
      Trial.expire(user)
      {:ok, :created}
    else
      data -> {:error, data}
    end
  end

  def create(conn, %{"payment_method" => %{"payment_method_id" => payment_method_id} = payment_method}) do
    with {:ok, %Stripe.PaymentMethod{billing_details: billing_details, card: card}} <- Stripe.PaymentMethod.retrieve(payment_method_id),
         {:ok, %User{} = user} <- conn.assigns |> Map.fetch(:user),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <- find_or_create_stripe_customer(
           nil,
           user.id,
           payment_method_id
         ),
         {:ok, %Stripe.Subscription{}} <- create_subscription(
           customer_stripe_id,
           payment_method["plan_id"],
           user
         ) do
      create_or_update_card_info(
        %{
          user_id: user.id,
          customer_id: customer_stripe_id,
          payment_method: "card",
          billing_details: billing_details,
          card_info: card
        }
      )
      Trial.expire(user)
      {:ok, :created}
    else
      data -> {:error, data}
    end
  end

  defp create_subscription(customer_stripe_id, plan_id, user) do
    if plan_id do
      Stripe.Subscription.create(
       %{
          customer: customer_stripe_id,
          items: [%{plan: plan_id}],
          payment_behavior: "allow_incomplete"
        }
      )
    else
      set_lifetime_subscription(user)
      {:ok, %Stripe.Subscription{}}
    end
  end

  defp find_or_create_stripe_customer(token, user_id, payment_method_id) do
    case Payments.get_stripe_by_user_id(user_id) do
      nil ->
        create_stripe_customer(token, payment_method_id)
      %Skoller.Payments.Stripe{customer_id: customer_id} ->
        maybe_create_stripe_customer(token, customer_id, payment_method_id)
      error -> error
    end
  end

  defp maybe_create_stripe_customer(token, customer_id, payment_method_id)do
    case Stripe.Customer.retrieve(customer_id) do
      {:ok, customer} ->
        {:ok, customer}
      {:error, %Stripe.Error{code: :invalid_request_error}} ->
        create_stripe_customer(token, payment_method_id)
      error -> error
    end
  end

  defp create_stripe_customer(token, payment_method_id) do
    Stripe.Customer.create(
      %{description: "Staging test customer"}
      |> Map.merge(
        case {token, payment_method_id} do
          {token, nil} ->
            %{source: token}
          {nil, payment_method_id} ->
            %{
              invoice_settings: %{
                default_payment_method: payment_method_id
              },
              payment_method: payment_method_id
            }
        end
      )
    )
  end

  defp create_or_update_card_info(%{user_id: user_id} = params)do
    case Payments.get_stripe_by_user_id(user_id) do
      nil ->
        Payments.create_stripe(params)
      stripe ->
        stripe
        |> Payments.update_stripe(params)
    end
  end

  @doc """
    Set user's lifetime_subscription to true.
  """
  defp set_lifetime_subscription(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [set: [lifetime_subscription: true, trial: false]]
    )
    |> Repo.update_all([])
  end
end
