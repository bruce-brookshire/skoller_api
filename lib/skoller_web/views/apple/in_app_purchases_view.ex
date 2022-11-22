defmodule SkollerWeb.Apple.InAppPurchasesView do
  @moduledoc false
  use SkollerWeb, :view

  def render("submit_receipt_success.json", %{data: resp}) do
    %{
      message: "Receipt validated successfully and subscription created/updated",
      data: resp
    }
  end

  def render("submit_receipt_validation_success_subscription_failed.json", %{data: resp}) do
    %{
      message: "Receipt validated successfully but subscription creation/update failed",
      data: resp
    }
  end

  def render("submit_receipt_validation_failed.json", %{data: data}) do
    %{
      message: "Receipt validation failed",
      data: data
    }
  end

  def render("submit_receipt_nil_failure.json", nil) do
    %{message: "Unrecognized error encountered attempting to validate receipt and compile data."}
  end
end
