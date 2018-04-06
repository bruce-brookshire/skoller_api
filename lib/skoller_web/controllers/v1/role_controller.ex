defmodule SkollerWeb.Api.V1.RoleController do
  use SkollerWeb, :controller

  alias Skoller.Role
  alias Skoller.Repo
  alias SkollerWeb.RoleView

  def index(conn, %{}) do
    roles = Repo.all(Role)
    render(conn, RoleView, "index.json", roles: roles)
  end

  def show(conn, %{"id" => id}) do
    role = Repo.get!(Role, id)
    render(conn, RoleView, "show.json", role: role)
  end
end