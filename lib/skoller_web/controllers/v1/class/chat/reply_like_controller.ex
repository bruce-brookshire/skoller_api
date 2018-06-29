defmodule SkollerWeb.Api.V1.Class.Chat.ReplyLikeController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.ChatReplies.Like
  alias SkollerWeb.Class.ChatReplyView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Like.changeset(%Like{}, params)

    case Repo.insert(changeset) do
      {:ok, like} -> 
        like = like |> Repo.preload(:chat_reply)
        render(conn, ChatReplyView, "show.json", %{chat_reply: like.chat_reply, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_reply_id" => reply_id}) do
    like = Repo.get_by!(Like, chat_reply_id: reply_id, student_id: conn.assigns[:user].student_id)
    case Repo.delete(like) do
      {:ok, _struct} ->
        like = like |> Repo.preload(:chat_reply)
        render(conn, ChatReplyView, "show.json", %{chat_reply: like.chat_reply, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end