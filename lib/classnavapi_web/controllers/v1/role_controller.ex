defmodule ClassnavapiWeb.Api.V1.RoleController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.UserRole
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserRoleView

  import Ecto.Query

  def create(conn, %{"user_id" => user_id, "id" => role_id}) do

    changeset = UserRole.changeset(%UserRole{}, %{user_id: user_id, role_id: role_id})

    case Repo.insert(changeset) do
      {:ok, user_role} ->
        render(conn, UserRoleView, "show.json", user_role: user_role)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
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
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    user_roles = Repo.all(from ur in UserRole, where: ur.user_id == ^user_id)
    render(conn, UserRoleView, "index.json", user_roles: user_roles)
  end
end