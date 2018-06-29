defmodule SkollerWeb.Api.V1.Admin.Assignment.PostController do
  @moduledoc false

  use SkollerWeb, :controller
  
  alias Skoller.ChatPosts
  alias SkollerWeb.ChangesetView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def delete(conn, %{"id" => id}) do
    post = conn |> get_post(id)
    case ChatPosts.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  # If a student is attempting to delete, verify it is their post.
  defp get_post(%{assigns: %{user: %{student: %{id: student_id}}}}, id) do
    ChatPosts.get_post_by_student_and_id!(student_id, id)
  end
  defp get_post(_conn, id) do
    ChatPosts.get!(id)
  end
end