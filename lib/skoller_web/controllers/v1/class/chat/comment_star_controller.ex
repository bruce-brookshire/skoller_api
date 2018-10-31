defmodule SkollerWeb.Api.V1.Class.Chat.CommentStarController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.ChatComments
  alias SkollerWeb.Class.ChatCommentView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"chat_comment_id" => comment_id}) do
    case ChatComments.star_comment(comment_id, conn.assigns[:user].student_id) do
      {:ok, chat_comment} -> 
        render(conn, ChatCommentView, "show.json", %{chat_comment: chat_comment, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_comment_id" => comment_id}) do
    case ChatComments.unstar_comment(comment_id, conn.assigns[:user].student_id) do
      {:ok, chat_comment} ->
        render(conn, ChatCommentView, "show.json", %{chat_comment: chat_comment, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end