defmodule SkollerWeb.Api.V1.Stripe.SubscriptionItemView do
  use SkollerWeb, :view
  alias  SkollerWeb.Api.V1.Stripe.SubscriptionItemView
  alias SkollerWeb.Api.V1.Stripe.PlanView
  alias SkollerWeb.Api.V1.Stripe.PriceView

  def render("show.json", %{item: item}) do
    %{data: render_one(item, SubscriptionItemView, "item.json")}
  end

  def render("item.json", %{item: item}) do
    %{
      billing_thresholds: item.billing_thresholds,
      created: item.created,
      id: item.id,
      plan: render_one(item.plan, PlanView, "plan.json", as: :plan),
      price: render_one(item.price, PriceView, "price.json", as: :price)
    }
  end
end
