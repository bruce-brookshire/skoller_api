defmodule SkollerWeb.Api.V1.Stripe.SubscriptionController do
  use SkollerWeb, :controller
  alias Skoller.Payments

  def list_user_subscriptions(conn, _params)do
    with {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         %Skoller.Payments.Stripe{customer_id: customer_id} <- Payments.get_stripe_by_user_id(user_id),
         {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{customer: customer_id}) do
      render(conn, "index.json", %{subscriptions: subscriptions})
    else
      data -> process_errors(conn, data)
    end
  end

  def list_all_subscriptions(conn, _params)do
    with{:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list() do
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

  def create_subscription(
        conn,
        %{
          "payment_method" =>
            %{"type" => type, "plan_id" => plan_id,  "billing_details" => %{"email" => email} = billing_details} = payment_method
        }
      )do
    method = payment_method |> Map.delete("plan_id")
    with {:ok, %Skoller.Users.User{id: user_id} = user} <- conn.assigns
                                                           |> Map.fetch(:user),
         {:ok, %Stripe.PaymentMethod{id: payment_method, card: card}} <- Stripe.PaymentMethod.create(method),
         {:ok, %Stripe.Customer{id: customer_stripe_id}} <- find_or_create_stripe_customer(
           email,
           payment_method,
           user_id
         ),
         {:ok, %Stripe.Subscription{}} <- Stripe.Subscription.create(
           %{customer: customer_stripe_id, items: [%{plan: plan_id}], payment_behavior: "allow_incomplete"}
         )do
      create_or_update_card_info(
        %{
          user_id: user_id,
          customer_id: customer_stripe_id,
          payment_method: type,
          billing_details: billing_details,
          card_info: card
        }
      )
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

  defp find_or_create_stripe_customer(email, payment_method, user_id)do
    case Payments.get_stripe_by_user_id(user_id)  do
      nil ->
        Stripe.Customer.create(
          %{
            email: email,
            payment_method: payment_method,
            invoice_settings: %{
              default_payment_method: payment_method
            }
          }
        )
      %Skoller.Payments.Stripe{customer_id: customer_id} ->
        maybe_create_stripe_customer(email, payment_method, customer_id)
      error -> error

    end
  end

  defp maybe_create_stripe_customer(email, payment_method, customer_id)do
    case Stripe.Customer.retrieve(customer_id) do
      {:ok, customer} ->
        {:ok, customer}
      {:error, %Stripe.Error{code: :invalid_request_error}} ->
        Stripe.Customer.create(
          %{
            email: email,
            payment_method: payment_method,
            invoice_settings: %{
              default_payment_method: payment_method
            }
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
