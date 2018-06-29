defmodule SkollerWeb.RoleView do
  @moduledoc false
  use SkollerWeb, :view

  def render("index.json", %{roles: roles}) do
    render_many(roles, SkollerWeb.RoleView, "role.json")
  end

  def render("show.json", %{role: role}) do
    render_one(role, SkollerWeb.RoleView, "role.json")
  end

  def render("role.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name
    }
  end
end
