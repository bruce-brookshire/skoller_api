defmodule SkollerWeb.AuthView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.AuthView
  alias SkollerWeb.UserView

  def render("show.json", %{auth: auth}) do
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
      user: render_one(auth.user, UserView, "user_detail.json")
    })
  end

  def render("auth.json", %{auth: auth}) do
    %{
      user: render_one(auth, UserView, "user_detail.json")
    }
  end
end
