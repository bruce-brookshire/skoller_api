defmodule SkollerWeb.Api.V1.Stripe.PriceView do
  use SkollerWeb, :view
  alias  SkollerWeb.Api.V1.Stripe.PriceView

  def render("show.json", %{price: price}) do
    %{data: render_one(price, PriceView, "price.json")}
  end

  def render("price.json", %{price: price}) do
    %{
      active: price.active,
      billing_scheme: price.billing_scheme,
      created: price.created,
      currency: price.currency,
      id: price.id,
      product: price.product,
      recurring: price.recurring
    }
  end
end
