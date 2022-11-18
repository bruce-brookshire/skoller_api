defmodule SkollerWeb.Api.V1.Stripe.ProductView do
  use SkollerWeb, :view

  def render("product.json", %{product: product}) do
    %{
      active: product.active,
      created: product.created,
      description: product.description,
      id: product.id,
      livemode: product.livemode,
      name: product.name,
      object: product.object,
      url: product.url,
      updated: product.updated
    }
  end

  def render("products_with_price.json", %{product: product_item}) do
    product_item
  end
end
