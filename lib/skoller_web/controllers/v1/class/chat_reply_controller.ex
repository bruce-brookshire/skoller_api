defmodule SkollerWeb.Api.V1.Class.ChatReplyController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.ChatReplies.Reply
  alias SkollerWeb.Class.ChatReplyView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.ChatComments.Star, as: CommentStar
  alias Skoller.ChatPosts.Star, as: PostStar
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatNotifications

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth
  import Ecto.Query

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Reply.changeset(%Reply{}, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:reply, changeset)
    |> Ecto.Multi.run(:unread_post, &unread_post(&1.reply, conn.assigns[:user].student_id))
    |> Ecto.Multi.run(:unread_comments, &unread_comments(&1.reply, conn.assigns[:user].student_id))

    case Repo.transaction(multi) do
      {:ok, %{reply: reply}} -> 
        Task.start(ChatNotifications, :send_new_reply_notification, [reply, conn.assigns[:user].student_id])
        render(conn, ChatReplyView, "show.json", %{chat_reply: reply, current_student_id: conn.assigns[:user].student_id})
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def update(conn, %{"id" => id} = params) do
    reply_old = Repo.get_by!(Reply, id: id, student_id: conn.assigns[:user].student_id)
    
    changeset = Reply.changeset_update(reply_old, params)

    case Repo.update(changeset) do
      {:ok, reply} -> 
        render(conn, ChatReplyView, "show.json", %{chat_reply: reply, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp unread_post(reply, student_id) do
    items = from(s in PostStar)
    |> join(:inner, [s], c in Comment, c.chat_post_id == s.chat_post_id)
    |> where([s], s.is_read == true and s.student_id != ^student_id)
    |> where([s, c], c.id == ^reply.chat_comment_id)
    |> Repo.update_all(set: [is_read: false, updated_at: DateTime.utc_now])
    {:ok, items}
  end

  defp unread_comments(reply, student_id) do
    items = from(s in CommentStar)
    |> where([s], s.is_read == true and s.student_id != ^student_id)
    |> where([s], s.chat_comment_id == ^reply.chat_comment_id)
    |> Repo.update_all(set: [is_read: false, updated_at: DateTime.utc_now])
    {:ok, items}
  end
end