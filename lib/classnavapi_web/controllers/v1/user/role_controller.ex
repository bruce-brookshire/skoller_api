defmodule ClassnavapiWeb.Api.V1.User.RoleController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.UserRole
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserRoleView

  import Ecto.Query

  def index(conn, %{"user_id" => user_id}) do
    user_roles = Repo.all(from ur in UserRole, where: ur.user_id == ^user_id)
    render(conn, UserRoleView, "index.json", user_roles: user_roles)
  end
end