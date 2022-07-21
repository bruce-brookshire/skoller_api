defmodule SkollerWeb.Api.V1.Stripe.SubscriptionController do
  use SkollerWeb, :controller
  alias Skoller.Payments
  alias Skoller.Users.{Trial, Subscription}

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

  def create_subscription(conn, params) do
    case Subscription.create(conn, params) do
      {:ok, data} ->
        IO.inspect(data)
        json(conn, %{status: :ok, message: "Your subscription was successful", user: data.user, subscription: data.subscription})
      {:error, data} ->
        process_errors(conn, data)
    end
  end

  def update_apple_pay_subscription(conn, params) do
    case Subscription.update(conn, params) do
      {:ok, data} ->
        json(conn, %{status: :ok, message: "Your subscription was updated successful"})
      {:error, data} ->
        process_errors(conn, data)
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
        IO.inspect(data)
        conn
        |> put_status(200)
        |> json(%{error: :error, message: message})
      {:error, %{message: message}} ->
        IO.inspect(data, label: "new case")
        conn
        |> put_status(200)
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
