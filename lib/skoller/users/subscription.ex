defmodule Skoller.Users.Subscription do
  @moduledoc """
  The Users Subscription context.
  """

  alias Skoller.{Repo, Payments}
  alias Skoller.Users.{User, Trial}

  import Ecto.Query

  def create(conn, %{"payment_method" => payment_method, "email" => email}) do
    token = payment_method["token"]
    payment_method_id = payment_method["payment_method_id"]

    with {:ok, %Stripe.Token{card: %Stripe.Card{} = card}} <- retrieve_token(token),
         {:ok, %Stripe.PaymentMethod{} = stripe_payment_method} <-
           retrieve_payment_method(payment_method_id),
         {:ok, %User{} = user} <- conn.assigns |> Map.fetch(:user),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <-
           find_or_create_stripe_customer(
             token,
             user,
             email,
             payment_method_id
           ),
         {:ok, %Stripe.Subscription{} = subscription} <-
           create_subscription(
             customer_stripe_id,
             payment_method["plan_id"],
             user
           ) do
      create_or_update_card_info(
        %{
          user_id: user.id,
          customer_id: customer_stripe_id,
          payment_method: "card"
        }
        |> Map.merge(
          case {token, payment_method_id} do
            {_token, nil} ->
              %{card_info: %{card_id: card.id}}

            {nil, _payment_method_id} ->
              %{
                billing_details: stripe_payment_method.billing_details,
                card_info: stripe_payment_method.card
              }
          end
        )
      )

      Trial.expire(user)
      {:ok, %{user: Repo.get!(User, user.id), subscription: subscription}}
    else
      data ->
        {:error, data}
    end
  end

  def update(conn, %{"payment" => _payment_method}) do
    with {:ok, %User{} = user} <- conn.assigns |> Map.fetch(:user) do
      set_lifetime_subscription(user)
      Trial.expire(user)
      {:ok, :updated_succesfully}
    else
      data -> {:error, data}
    end
  end

  def update(conn, %{"customer_id" => customer_id}) do
    with {:ok, %User{} = user} <- conn.assigns |> Map.fetch(:user),
         {:ok, _payments} <-
           create_or_update_card_info(%{
             user_id: user.id,
             customer_id: customer_id,
             payment_method: "apple_pay"
           }) do
      Trial.expire(user)
      {:ok, :updated_succesfully}
    else
      data -> {:error, data}
    end
  end

  defp retrieve_token(token) do
    if token do
      Stripe.Token.retrieve(token)
    else
      {:ok, %Stripe.Token{card: %Stripe.Card{}}}
    end
  end

  defp retrieve_payment_method(id) do
    if id do
      Stripe.PaymentMethod.retrieve(id)
    else
      {:ok, %Stripe.PaymentMethod{}}
    end
  end

  defp create_subscription(customer_stripe_id, plan_id, user) do
    if plan_id do
      case Stripe.Subscription.create(%{
        customer: customer_stripe_id,
        items: [%{plan: plan_id}],
        payment_behavior: "allow_incomplete"
      }) do
        {:ok, %{status: "incomplete"}} ->
          Stripe.Customer.delete(customer_stripe_id)
          {:error, %{message: "Unable to complete payment. Please contact support."}}
        {:ok, subscription} ->
          {:ok, subscription}
        {:error, %Stripe.Error{} = error} -> {:ok, error}
      end
    else
      set_lifetime_subscription(user)
      {:ok, %Stripe.Subscription{}}
    end
  end

  defp find_or_create_stripe_customer(token, user, email, payment_method_id) do
    case Payments.get_stripe_by_user_id(user.id) do
      nil ->
        create_stripe_customer(token, payment_method_id, user, email)

      %Skoller.Payments.Stripe{customer_id: customer_id} ->
        maybe_create_stripe_customer(token, customer_id, payment_method_id, user, email)

      error ->
        error
    end
  end

  defp maybe_create_stripe_customer(token, customer_id, payment_method_id, user, email) do
    case Stripe.Customer.retrieve(customer_id) do
      {:ok, customer} ->
        {:ok, customer}

      {:error, %Stripe.Error{code: :invalid_request_error}} ->
        create_stripe_customer(token, payment_method_id, user, email)

      error ->
        error
    end
  end

  defp create_stripe_customer(token, payment_method_id, user, email) do
    Stripe.Customer.create(
      %{
        metadata: %{
          student_id: user.student.id,
          user_id: user.id,
        },
        email: email,
        phone: user.student.phone,
        name: "#{user.student.name_first} #{user.student.name_last}"
      }
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

  defp create_or_update_card_info(%{user_id: user_id} = params) do
    case Payments.get_stripe_by_user_id(user_id) do
      nil ->
        Payments.create_stripe(params)

      stripe ->
        stripe
        |> Payments.update_stripe(params)
    end
  end

  # Set user's lifetime_subscription to true.
  defp set_lifetime_subscription(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [set: [lifetime_subscription: true, trial: false]]
    )
    |> Repo.update_all([])
  end
end
