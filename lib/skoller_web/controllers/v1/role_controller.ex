defmodule SkollerWeb.Api.V1.RoleController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Roles
  alias SkollerWeb.RoleView

  def index(conn, %{}) do
    roles = Roles.get_roles()
    render(conn, RoleView, "index.json", roles: roles)
  end

  def show(conn, %{"id" => id}) do
    role = Roles.get_role_by_id!(id)
    render(conn, RoleView, "show.json", role: role)
  end
end