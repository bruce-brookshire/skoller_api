defmodule SkollerWeb.Api.V1.Apple.InAppPurchasesController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Apple.InAppPurchasesView
  alias Skoller.Schema.Subscription
  alias Skoller.Contexts.Subscriptions.Apple.InAppPurchases
  alias Skoller.Contexts.Subscriptions, as: SubscriptionContexts
  alias SkollerWeb.Api.V1.Stripe.SubscriptionView

  def submit_receipt(conn,
    %{
      "skollerUserId" => user_id,
      "verificationData" => %{
        "serverVerificationData" => encoded_receipt_data
      }
    } = params) do
    InAppPurchases.verify_receipt(encoded_receipt_data)
    |> case do
      {:ok, data} ->
        case InAppPurchases.create_update_subscription(data, user_id) do
          {:ok, subscription} ->
            conn
            |> put_view(InAppPurchasesView)
            |> render("submit_receipt_success.json", %{data: subscription})
          {:error, changeset} ->
            conn
            |> put_view(InAppPurchasesView)
            |> render("submit_receipt_validation_success_subscription_failed.json", %{data: changeset.errors})
        end

      {:error, resp} ->
        conn
        |> put_view(InAppPurchasesView)
        |> render("submit_receipt_validation_failed.json", %{data: resp})
      {:error, nil} ->
        conn
        |> put_view(InAppPurchasesView)
        |> render("submit_receipt_nil_failure.json", nil)
    end
  end

  def get_subscription(conn, %{"user_id" => user_id}) do
    case Skoller.Contexts.Subscriptions do
      %Subscription{} = subscription ->
        conn
        |> put_view(SubscriptionView)
        |> render("index.json", %{subscription: subscription})
      nil ->
        conn
        |> put_status(404)
        |> put_view(SubscriptionView)
        |> render("subscription_not_found.json", nil)
    end
  end

  def transaction_updated(conn, params) do
    IO.inspect(params, label: "TRANSACTION UPDATED WEBHOOK")

    conn
    |> Plug.Conn.send_resp(200, "Received")
  end
end
