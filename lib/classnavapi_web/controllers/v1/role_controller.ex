defmodule ClassnavapiWeb.Api.V1.RoleController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Role
  alias Classnavapi.Repo
  alias ClassnavapiWeb.RoleView

  def index(conn, %{}) do
    roles = Repo.all(Role)
    render(conn, RoleView, "index.json", roles: roles)
  end

  def show(conn, %{"id" => id}) do
    role = Repo.get!(Role, id)
    render(conn, RoleView, "show.json", role: role)
  end
end