defmodule SkollerWeb.Api.V1.Admin.Class.ChatReplyController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.ChatReplies
  alias SkollerWeb.ChangesetView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(conn, %{"id" => id}) do
    reply = conn |> get_reply(id)
    case ChatReplies.delete(reply) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  # If a student is attempting to delete, verify it is their reply.
  defp get_reply(%{assigns: %{user: %{student: %{id: student_id}}}}, id) do
    ChatReplies.get_reply_by_student_and_id!(student_id, id)
  end
  defp get_reply(_conn, id) do
    ChatReplies.get!(id)
  end
end