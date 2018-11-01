defmodule SkollerWeb.Api.V1.Admin.Class.ChatCommentController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.ChatComments
  alias SkollerWeb.ChangesetView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete_comment(conn, %{"id" => id}) do
    comment = conn |> get_comment(id)
    case ChatComments.delete(comment) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  # If a student is attempting to delete, verify it is their comment.
  defp get_comment(%{assigns: %{user: %{student: %{id: student_id}}}}, id) do
    ChatComments.get_comment_by_student_and_id!(student_id, id)
  end
  defp get_comment(_conn, id) do
    ChatComments.get_comment!(id)
  end
end