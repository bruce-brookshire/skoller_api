defmodule SkollerWeb.Apple.InAppPurchasesView do
  @moduledoc false
  use SkollerWeb, :view

  def render("submit_receipt.json", params) do
    %{
      status: "Receipt Received"
    }
  end
end
