defmodule SkollerWeb.Api.V1.Stripe.InvoiceView do
  use SkollerWeb, :view
  alias SkollerWeb.Api.V1.Stripe.LineItemView

  def render("invoice.json", %{invoice: invoice}) do
    %Stripe.List{data: lines } = invoice.lines
    %{
      period_end: invoice.period_end,
      default_payment_method: invoice.default_payment_method,
      payment_settings: invoice.payment_settings,
      account_tax_ids: invoice.account_tax_ids,
      customer_email: invoice.customer_email,
      created: invoice.created,
      starting_balance: invoice.starting_balance,
      customer: invoice.customer,
      ending_balance: invoice.ending_balance,
      next_payment_attempt: invoice.next_payment_attempt,
      status: invoice.status,
      total: invoice.total,
      subscription: invoice.subscription,
      automatic_tax: invoice.automatic_tax,
      billing_reason: invoice.billing_reason,
      collection_method: invoice.collection_method,
      amount_remaining: invoice.amount_remaining,
      receipt_number: invoice.receipt_number,
      customer_name: invoice.customer_name,
      paid: invoice.paid,
      transfer_data: invoice.transfer_data,
      default_source: invoice.default_source,
      attempted: invoice.attempted,
      description: invoice.description,
      statement_descriptor: invoice.statement_descriptor,
      object: invoice.object,
      application_fee_amount: invoice.application_fee_amount,
      attempt_count: invoice.attempt_count,
      pre_payment_credit_notes_amount: invoice.pre_payment_credit_notes_amount,
      on_behalf_of: invoice.on_behalf_of,
      discount: invoice.discount,
      webhooks_delivered_at: invoice.webhooks_delivered_at,
      subscription_proration_date: invoice.subscription_proration_date,
      post_payment_credit_notes_amount: invoice.post_payment_credit_notes_amount,
      subtotal: invoice.subtotal,
      period_start: invoice.period_start,
      customer_address: invoice.customer_address,
      hosted_invoice_url: invoice.hosted_invoice_url,
      amount_due: invoice.amount_due,
      account_country: invoice.account_country,
      customer_tax_exempt: invoice.customer_tax_exempt,
      currency: invoice.currency,
      lines: render_many(lines, LineItemView, "item.json", as: :item)
    }
  end
end
