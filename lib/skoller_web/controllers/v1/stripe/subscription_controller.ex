defmodule SkollerWeb.Api.V1.Stripe.SubscriptionController do
  use SkollerWeb, :controller
  alias Skoller.Users.{Trial, Subscription}
  alias Skoller.Contexts.Subscriptions
  alias Skoller.Contexts.Subscriptions.Stripe.StripePurchases

  def list_user_subscriptions(conn, _params) do
    with {:ok, %Skoller.Users.User{id: user_id}} <- conn.assigns |> Map.fetch(:user),
         %Skoller.Schema.Subscription{} = subscription <-
          Subscriptions.get_subscription_by_user_id(user_id) do
      render(conn, "index.json", %{subscription: subscription})
    else
      data ->
        unless data do
          json(conn, %{data: []})
        else
          process_errors(conn, data)
        end
    end
  end

  def list_all_subscriptions(conn, _params) do
    case Stripe.Subscription.list(%{status: "all"}) do
      {:ok, %Stripe.List{data: subscriptions}} ->
        render(conn, "index.json", %{subscriptions: subscriptions})
      _ ->
        process_errors(conn, %{message: "Unable to get subscriptions."})
    end
  end

  def get_available_plans_and_products(conn, _params) do
    with {:ok, %Stripe.List{data: plans}} <- Stripe.Plan.list(%{active: true}),
      {:ok, %Stripe.List{data: products}} <- Stripe.Product.list(%{active: true}) do
        products =
          products
          |> Enum.filter(& &1.name == "Lifetime")
          |> Enum.reduce([], fn product, acc ->

            [
              %{
                product: product,
                price: with {:ok, %Stripe.Price{unit_amount: price_amt}} <- Stripe.Price.retrieve(product.default_price) do
                    price_amt
                  else
                    data -> nil
                  end
              }
              | acc
            ]
          end)
          |> Enum.sort_by(& &1.product.updated, :desc)

      render(conn, "plans_and_products.json", %{plans: plans |> Enum.sort_by(& &1.amount, :desc), products: products})
    else
      data -> process_errors(conn, data)
    end
  end

  def list_all_products(conn, _params)do
    with {:ok, %Stripe.List{data: products}} <- Stripe.Product.list(%{active: true}) do
      render(conn, "products.json", %{products: products})
    else
      data -> process_errors(conn, data)
    end
  end

  def list_all_plans(conn, _params)do
    with {:ok, %Stripe.List{data: plans}} <- Stripe.Plan.list(%{active: true}) do
      render(conn, "plans.json", %{plans: plans})
    else
      data -> process_errors(conn, data)
    end
  end

  def create_subscription(conn, params) do
    case Subscription.create(conn, params) do
      {:ok, data} ->
        json(conn, %{status: :ok, message: "Your subscription was successful", user: data.user, subscription: data.subscription})
      {:error, data} ->
        process_errors(conn, data)
    end
  end

  def update_apple_pay_subscription(conn, params) do
    case Subscription.update(conn, params) do
      {:ok, _data} ->
        json(conn, %{status: :ok, message: "Your subscription was updated successful"})
      {:error, data} ->
        process_errors(conn, data)
    end
  end

  def list_upcoming_payments(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id}} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Schema.Subscription{customer_id: customer_id} <- Subscriptions.get_subscription_by_user_id(user_id),
         {:ok, invoice} <- Stripe.Invoice.upcoming(%{customer: customer_id})do
      render(conn, "invoice.json", invoice: invoice)
    else
      data -> process_errors(conn, data)
    end

  end

  def list_billing_history(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id}} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Schema.Subscription{customer_id: customer_id} <- Subscriptions.get_subscription_by_user_id(user_id),
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
    with {:ok, subscription} <- Stripe.Subscription.update(subscription_id, %{cancel_at_period_end: true}),
    %Skoller.Schema.Subscription{} = subscription <- StripePurchases.cancel_stripe_subscription(subscription) do
      render(conn, "show.json", %{subscription: subscription})
    else
      data ->
        process_errors(conn, data)
    end
  end

  def update_subscription(conn, %{"subscription_id" => subscription_id, "subscription_params" => subscription_params}) do
    with {:ok, subscription} <- Stripe.Subscription.update(subscription_id, subscription_params) do
      render(conn, "show.json", %{subscription: subscription})
    else
      data -> process_errors(conn, data)
    end
  end

  defp process_errors(conn, data) do
    case data do
      {:error, %Stripe.Error{code: _code, message: message}} ->
        conn
        |> put_status(200)
        |> json(%{error: :error, message: message})
      {:error, %{message: message}} ->
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
