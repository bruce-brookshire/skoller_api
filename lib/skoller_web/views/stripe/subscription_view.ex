defmodule SkollerWeb.Api.V1.Stripe.SubscriptionView do
  use SkollerWeb, :view
  alias  SkollerWeb.Api.V1.Stripe.SubscriptionView
  alias  SkollerWeb.Api.V1.Stripe.PlanView
  alias SkollerWeb.Api.V1.Stripe.SubscriptionItemView
  alias SkollerWeb.Api.V1.Stripe.InvoiceView
  alias SkollerWeb.Api.V1.Stripe.ProductView

  def render("index.json", %{subscriptions: subscriptions}) do
    %{data: render_many(subscriptions, SubscriptionView, "subscription.json")}
  end

  def render("plans.json", %{plans: plans}) do
    %{data: render_many(plans, PlanView, "plan.json", as: :plan)}
  end

  def render("products.json", %{products: products}) do
    %{data: render_many(products, ProductView, "product.json", as: :product)}
  end

  def render("invoice.json", %{invoice: invoice}) do
    %{data: render_one(invoice, InvoiceView, "invoice.json")}
  end

  def render("invoices.json", %{invoice: invoice}) do
    %{data: render_many(invoice, InvoiceView, "invoice.json")}
  end

  def render("show.json", %{subscription: subscription}) do
    %{data: render_one(subscription, SubscriptionView, "subscription.json")}
  end

  def render("subscription.json", %{subscription: subscription}) do
    %Stripe.List{data: items} = subscription.items
    %{
      id: subscription.id,
      current_period_start: subscription.current_period_start,
      created: subscription.created,
      canceled_at: subscription.canceled_at,
      status: subscription.status,
      plan: render_one(subscription.plan, PlanView, "plan.json", as: :plan),
      latest_invoice: subscription.latest_invoice,
      trial_start: subscription.trial_start,
      customer: subscription.customer,
      days_until_due: subscription.days_until_due,
    quantity: subscription.quantity,
    items:  render_many(items, SubscriptionItemView, "item.json", as: :item),
    }
  end
end
