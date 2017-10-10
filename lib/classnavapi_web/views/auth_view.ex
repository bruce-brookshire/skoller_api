defmodule ClassnavapiWeb.AuthView do
  use ClassnavapiWeb, :view

  def render("show.json", %{token: token}) do
    render_one(token, ClassnavapiWeb.AuthView, "token.json")
  end

  def render("token.json", token) do
    %{token: token.auth}
  end
end
