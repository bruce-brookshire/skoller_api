defmodule SkollerWeb.Apple.InAppPurchasesView do
  @moduledoc false
  use SkollerWeb, :view

  def render("submit_receipt.json", params) do
    %{
      status: "Receipt Received"
    }
  end

  def render("transaction_updated.json", params) do
    %{
      status: "Receieved Update"
    }
  end
end
