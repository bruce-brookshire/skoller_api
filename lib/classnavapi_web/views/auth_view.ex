defmodule ClassnavapiWeb.AuthView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.AuthView
  alias ClassnavapiWeb.UserView

  def render("show.json", %{auth: auth}) do
    render_one(auth, AuthView, "auth.json")
  end

  def render("auth.json", %{auth: auth}) do
    %{token: auth.token}
    |> Map.merge(%{
      user: render_one(auth.user, UserView, "user_detail.json")
    })
  end
end
