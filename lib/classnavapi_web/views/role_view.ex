defmodule ClassnavapiWeb.RoleView do
  use ClassnavapiWeb, :view

  def render("index.json", %{roles: roles}) do
    render_many(roles, ClassnavapiWeb.RoleView, "role.json")
  end

  def render("show.json", %{role: role}) do
    render_one(role, ClassnavapiWeb.RoleView, "role.json")
  end

  def render("role.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name
    }
  end
end
