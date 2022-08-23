defmodule SkollerWeb.AuthView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.AuthView
  alias SkollerWeb.UserView
  alias SkollerWeb.Api.V1.Stripe.SubscriptionView

  def render("show.json", %{auth: auth}) do
    render_one(auth, AuthView, "auth.json")
  end

  def render("show.json", %{token: token, user: %{student: student} = user}) when not(is_nil(student)) do
    user = render_one(user, UserView, "user_detail.json")

    auth =
      Map.new()
      |> Map.put(:token, token)
      |> Map.put(:user, user)


    render_one(auth, AuthView, "auth.json")
  end

  def render("show.json", %{token: token, user: user}) do
    auth = Map.new()
    |> Map.put(:token, token)
    |> Map.put(:user, user)
    render_one(auth, AuthView, "auth.json")
  end

  def render("auth.json", %{auth: %{token: token} = auth}) do
    %{token: token}
  |> Map.merge(%{
      subscriptions: (render_many(auth.subscriptions, SubscriptionView, "subscription.json", as: :subscription)),
      user: render_one(auth.user, UserView, "user_detail.json")
    })
  end

  def render("auth.json", %{auth: auth}) do
    %{
      user: render_one(auth, UserView, "user_detail.json"),
      subscriptions: render_many(auth.subscriptions, SubscriptionView, "subscription.json", as: :subscriptions)
    }
  end
end
