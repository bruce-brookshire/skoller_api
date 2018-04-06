defmodule SkollerWeb.Api.V1.Admin.Class.ChatReplyController do
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Reply

  import SkollerWeb.Helpers.AuthPlug
  import SkollerWeb.Helpers.ChatPlug

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(%{assigns: %{user: %{student: %{id: student_id}}}} = conn, %{"id" => id}) do
    reply = Repo.get_by!(Reply, student_id: student_id, id: id)
    case Repo.delete(reply) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    reply = Repo.get!(Reply, id)
    case Repo.delete(reply) do
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