defmodule SkollerWeb.Api.V1.Admin.User.RoleController do
  @moduledoc false
  use SkollerWeb, :controller

  alias SkollerWeb.UserRoleView
  alias Skoller.UserRoles

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{"user_id" => user_id, "id" => role_id}) do
    case UserRoles.add_role(%{user_id: user_id, role_id: role_id}) do
      {:ok, user_role} ->
        render(conn, UserRoleView, "show.json", user_role: user_role)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    user_roles = UserRoles.get_roles_for_user(user_id)
    render(conn, UserRoleView, "index.json", user_roles: user_roles)
  end

  def delete(conn, %{"user_id" => user_id, "id" => role_id}) do
    user_role = UserRoles.get_role_by_ids!(user_id, role_id)
    case UserRoles.delete_role(user_role) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end