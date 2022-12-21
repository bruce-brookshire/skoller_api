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

  def render("plans_and_products.json", %{plans: plans, products: products}) do
    %{
      data: %{
        plans: render_many(plans, PlanView, "plan.json", as: :plan),
        products: render_many(products, ProductView, "products_with_price.json", as: :product)
      }
    }
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
    %{
      id: subscription.transaction_id,
      cancelAt: subscription.cancel_at_ms,
      created: subscription.created_at_ms,
      status: subscription.current_status,
      expirationIntent: subscription.expiration_intent,
      interval: subscription.renewal_interval,
      platform: subscription.platform,
      user_id: subscription.user_id
    }
  end

  def render("subscription_not_found.json", nil) do
    %{
      status: 404,
      message: "Subscription not found."
    }
  end
end
