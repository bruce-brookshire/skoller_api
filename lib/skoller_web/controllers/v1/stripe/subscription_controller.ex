defmodule SkollerWeb.Api.V1.Stripe.SubscriptionController do
  use SkollerWeb, :controller
  alias Skoller.Payments
  alias Skoller.Users.Trial

  def list_user_subscriptions(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Payments.Stripe{customer_id: customer_id} <- Payments.get_stripe_by_user_id(user_id),
         {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{customer: customer_id, status: "all"}) do
      render(conn, "index.json", %{subscriptions: subscriptions})
    else
      data ->
        unless data do
          json(conn, %{data: []})
        else
          process_errors(conn, data)
        end
    end
  end

  def list_all_subscriptions(conn, _params)do
    with{:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{status: "all"}) do
      render(conn, "index.json", %{subscriptions: subscriptions})
    else
      data -> process_errors(conn, data)
    end
  end


  def list_all_products(conn, _params)do
    with {:ok, %Stripe.List{data: products}} <- Stripe.Product.list() do
      render(conn, "products.json", %{products: products})
    else
      data -> process_errors(conn, data)
    end
  end

  def list_all_plans(conn, _params)do
    with {:ok, %Stripe.List{data: plans}} <- Stripe.Plan.list() do
      render(conn, "plans.json", %{plans: plans})
    else
      data -> process_errors(conn, data)
    end
  end

  def create_subscription(conn, %{"payment_method" => %{"plan_id" => plan_id, "token" => token} = payment_method}) do
    with {:ok, %Stripe.Token{card:  %Stripe.Card{id: card_id}}} <- Stripe.Token.retrieve(token),
         {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <- find_or_create_stripe_customer(
           token,
           user_id
         ),
         {:ok, %Stripe.Subscription{}} <- Stripe.Subscription.create(
           %{
              customer: customer_stripe_id,
              items: [%{plan: plan_id}],
              payment_behavior: "allow_incomplete"
            }
          )do
      create_or_update_card_info(
        %{
          user_id: user_id,
          customer_id: customer_stripe_id,
          payment_method: "card",
          card_info: %{card_id: card_id}
        }
      )
      Trial.expire(user)
      conn
      |> json(%{status: :ok, message: "Your subscription was successful"})
    else
      data -> process_errors(conn, data)
    end
  end

  def create_subscription(conn, %{"payment_method" => %{"token" => token} = payment_method}) do
    with {:ok, %Stripe.Token{card:  %Stripe.Card{id: card_id}}} <- Stripe.Token.retrieve(token),
         {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <- find_or_create_stripe_customer(
           token,
           user_id
         ) do
      create_or_update_card_info(
        %{
          user_id: user_id,
          customer_id: customer_stripe_id,
          payment_method: "card",
          card_info: %{card_id: card_id}
        }
      )
      Skoller.Users.Subscription.set_lifetime_subscription(user)
      Trial.expire(user)
      conn
      |> json(%{status: :ok, message: "Your subscription was successful"})

    else
      data -> process_errors(conn, data)
    end
  end

  def list_upcoming_payments(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Payments.Stripe{customer_id: customer_id} <- Payments.get_stripe_by_user_id(user_id),
         {:ok, invoice} <- Stripe.Invoice.upcoming(%{customer: customer_id})do
      render(conn, "invoice.json", invoice: invoice)
    else
      data -> process_errors(conn, data)
    end

  end

  def list_billing_history(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Payments.Stripe{customer_id: customer_id} <- Payments.get_stripe_by_user_id(user_id),
         {:ok, invoice} <- Stripe.Invoice.upcoming(%{customer: customer_id}) do
      render(conn, "invoice.json", invoice: invoice)
    else
      data -> process_errors(conn, data)
    end
  end

  def start_trial_for_all_users(conn, _) do
    Trial.start_trial_for_all_users()
    json(conn, %{status: :ok, message: "Your successfully started all users' trial"})
  end

  defp find_or_create_stripe_customer(token, user_id)do
    case Payments.get_stripe_by_user_id(user_id)  do
      nil ->
        Stripe.Customer.create(
          %{
            description: "Staging test customer",
            source: token
          }
        )
      %Skoller.Payments.Stripe{customer_id: customer_id} ->
        maybe_create_stripe_customer(token, customer_id)
      error -> error

    end
  end

  defp maybe_create_stripe_customer(token, customer_id)do
    case Stripe.Customer.retrieve(customer_id) do
      {:ok, customer} ->
        {:ok, customer}
      {:error, %Stripe.Error{code: :invalid_request_error}} ->
        Stripe.Customer.create(
          %{
            description: "Staging test customer",
            source: token
          }
        )
      error -> error
    end
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

  def cancel_subscription(conn, %{"subscription_id" => subscription_id}) do
    with {:ok, subscription} <- Stripe.Subscription.update(subscription_id, %{cancel_at_period_end: true}) do
      render(conn, "show.json", %{subscription: subscription})
    else
      data -> process_errors(conn, data)
    end
  end

  def update_subscription(conn, %{"subscription_id" => subscription_id, "subscription_params" => subscription_params}) do
    with {:ok, subscription} <- Stripe.Subscription.update(subscription_id, subscription_params) do
      render(conn, "show.json", %{subscription: subscription})
    else
      data -> process_errors(conn, data)
    end
  end

  defp process_errors(conn, data)do
    case data do
      {:error, %Stripe.Error{code: _code, message: message}} ->
        conn
        |> put_status(400)
        |> json(%{error: :error, message: message})
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: :error, message: "User not found in the customers list"})
      _ ->
        conn
        |> put_status(400)
        |> json(%{error: :error, message: "Something went wrong while processing your request"})
    end
  end
end
