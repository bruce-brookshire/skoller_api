defmodule ClassnavapiWeb.UserView do
  use ClassnavapiWeb, :view

  def render("index.json", %{users: users}) do
    render_many(users, ClassnavapiWeb.UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, ClassnavapiWeb.UserView, "user.json")
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      email: user.email}
  end
end
