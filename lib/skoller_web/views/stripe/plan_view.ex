defmodule SkollerWeb.Api.V1.Stripe.PlanView do
  use SkollerWeb, :view
  alias  SkollerWeb.Api.V1.Stripe.PlanView

  def render("show.json", %{plan: plan}) do
    %{data: render_one(plan, PlanView, "plan.json")}
  end

  def render("plan.json", %{plan: plan}) do
    %{
      active: plan.active,
      amount: plan.amount,
      amount_decimal: plan.amount_decimal,
      currency: plan.currency,
      created: plan.created,
      id: plan.id,
      interval: plan.interval,
      interval_count: plan.interval_count,
      name: plan.name,
     product: plan.product
    }
  end
end
