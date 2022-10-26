defmodule SkollerWeb.Api.V1.Apple.InAppPurchasesController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Apple.InAppPurchasesView

  def submit_receipt(conn, params) do
    IO.inspect(params, label: "PARAMS")

    conn
    |> put_view(InAppPurchasesView)
    |> render("submit_receipt.json", %{})
  end
end
