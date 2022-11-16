defmodule SkollerWeb.Api.V1.Apple.InAppPurchasesController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Apple.InAppPurchasesView
  alias Skoller.Contexts.Subscriptions.Apple.InAppPurchases

  def submit_receipt(conn,
    %{
      "purchaseID" => purchase_id,
      "productID" => product_id,
      "verificationData" => %{
        "serverVerificationData" => encoded_receipt_data
      }
    } = params) do
    result = InAppPurchases.verify_receipt(encoded_receipt_data)
    IO.inspect(result)

    conn
    |> put_view(InAppPurchasesView)
    |> render("submit_receipt.json", %{})
  end

  def transaction_updated(conn, params) do
    IO.inspect(params, label: "TRANSACTION UPDATED WEBHOOK")

    conn
    |> Plug.Conn.send_resp(200, "Received")
  end
end
