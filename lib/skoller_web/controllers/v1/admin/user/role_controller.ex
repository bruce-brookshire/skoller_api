defmodule SkollerWeb.Api.V1.Admin.User.RoleController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.UserRole
  alias Skoller.Repo
  alias SkollerWeb.UserRoleView

  import Ecto.Query
  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{"user_id" => user_id, "id" => role_id}) do

    changeset = UserRole.changeset(%UserRole{}, %{user_id: user_id, role_id: role_id})

    case Repo.insert(changeset) do
      {:ok, user_role} ->
        render(conn, UserRoleView, "show.json", user_role: user_role)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    user_roles = Repo.all(from ur in UserRole, where: ur.user_id == ^user_id)
    render(conn, UserRoleView, "index.json", user_roles: user_roles)
  end

  def delete(conn, %{"user_id" => user_id, "id" => role_id}) do
    user_role = Repo.get_by!(UserRole, user_id: user_id, role_id: role_id)
    case Repo.delete(user_role) do
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