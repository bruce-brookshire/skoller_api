defmodule ClassnavapiWeb.Api.V1.Admin.Assignment.PostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def delete(%{assigns: %{user: %{student: %{id: student_id}}}} = conn, %{"id" => id}) do
    post = Repo.get_by!(Post, student_id: student_id, id: id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end