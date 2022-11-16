defmodule SkollerWeb.Api.V1.Stripe.SubscriptionView do
  use SkollerWeb, :view
  alias  SkollerWeb.Api.V1.Stripe.SubscriptionView
  alias  SkollerWeb.Api.V1.Stripe.PlanView
  alias SkollerWeb.Api.V1.Stripe.SubscriptionItemView
  alias SkollerWeb.Api.V1.Stripe.InvoiceView
  alias SkollerWeb.Api.V1.Stripe.ProductView

  def render("index.json", %{subscription: subscription}) do
    %{data: render_one(subscription, SubscriptionView, "subscription.json")}
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
    IO.inspect(subscription, label: "SUBBY")
    %{
      id: subscription.transaction_id,
      cancelAt: subscription.cancel_at_unix_ts,
      created: subscription.current_status_unix_ts,
      status: subscription.current_status,
      expirationIntent: subscription.expiration_intent,
      interval: subscription.renewal_interval,
    }
    # %{
    #   id: subscription.transaction_id,
    #   cancel_at_period_end: subscription.cancel_at_period_end,
    #   created: subscription.created,
    #   canceled_at: subscription.canceled_at,
    #   status: subscription.status,
    #   plan: render_one(subscription.plan, PlanView, "plan.json", as: :plan),
    #   latest_invoice: subscription.latest_invoice,
    #   trial_start: subscription.trial_start,
    #   customer: subscription.customer,
    #   days_until_due: subscription.days_until_due,
    #   quantity: subscription.quantity
    # }
  end
end
