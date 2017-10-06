defmodule ClassnavapiWeb.Api.V1.RoleController do
  use ClassnavapiWeb, :controller
  
  def create(conn, %{"user_id" => user_id, "id" => role_id}) do

    changeset = Classnavapi.UserRole.changeset(%Classnavapi.UserRole{}, %{user_id: user_id, role_id: role_id})

    case Classnavapi.Repo.insert(changeset) do
      {:ok, user_role} ->
        render(conn, ClassnavapiWeb.UserRoleView, "show.json", user_role: user_role)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end