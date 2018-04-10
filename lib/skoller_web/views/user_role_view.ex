defmodule SkollerWeb.UserRoleView do
  use SkollerWeb, :view

  def render("index.json", %{user_roles: user_roles}) do
    render_many(user_roles, SkollerWeb.UserRoleView, "user_role.json")
  end

  def render("show.json", %{user_role: user_role}) do
    render_one(user_role, SkollerWeb.UserRoleView, "user_role.json")
  end

  def render("user_role.json", %{user_role: user_role}) do
    %{user_id: user_role.user_id,
      role_id: user_role.role_id}
  end
end
