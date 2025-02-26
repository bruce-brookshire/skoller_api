defmodule SkollerWeb.Class.ChatCommentView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.ChatCommentView
  alias SkollerWeb.Class.ChatReplyView
  alias Skoller.Chats
  alias SkollerWeb.Class.Chat.LikeView
  alias Skoller.ChatComments.Star

  def render("index.json", %{chat_comments: chat_comments}) do
    render_many(chat_comments, ChatCommentView, "chat_comment.json")
  end

  def render("show.json", %{chat_comment: chat_comment, current_student_id: current_student_id}) do
    render_one(chat_comment, ChatCommentView, "chat_comment_detail.json", %{current_student_id: current_student_id})
  end

  def render("show.json", %{chat_comment: chat_comment}) do
    render_one(chat_comment, ChatCommentView, "chat_comment_detail.json")
  end

  # TODO: Remove to_iso8601 modification
  def render("chat_comment.json", %{chat_comment: chat_comment}) do
    chat_comment = chat_comment |> Repo.preload([:student, :chat_replies])
    %{
      comment: chat_comment.comment,
      student: render_one(chat_comment.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_comment.id,
      replies: render_many(chat_comment.chat_replies, ChatReplyView, "chat_reply.json"),
      inserted_at: NaiveDateTime.to_iso8601(chat_comment.inserted_at) <> "Z"
    }
  end

  # TODO: Remove to_iso8601 modification
  def render("chat_comment_detail.json", %{chat_comment: chat_comment, current_student_id: student_id}) do
    chat_comment = chat_comment |> Repo.preload([:student, :chat_replies, :likes])
    %{
      comment: chat_comment.comment,
      student: render_one(chat_comment.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_comment.id,
      replies: render_many(chat_comment.chat_replies, ChatReplyView, "chat_reply_detail.json", %{current_student_id: student_id}),
      likes: render_many(chat_comment.likes, LikeView, "like.json"),
      is_liked: chat_comment |> Chats.is_liked(student_id),
      is_starred: chat_comment |> is_starred(student_id),
      inserted_at: NaiveDateTime.to_iso8601(chat_comment.inserted_at) <> "Z"
    }
  end
      
  # TODO: Remove to_iso8601 modification
  def render("chat_comment_detail.json", %{chat_comment: chat_comment}) do
    chat_comment = chat_comment |> Repo.preload([:student, :chat_replies, :likes])
    %{
      comment: chat_comment.comment,
      student: render_one(chat_comment.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_comment.id,
      replies: render_many(chat_comment.chat_replies, ChatReplyView, "chat_reply_detail.json"),
      likes: render_many(chat_comment.likes, LikeView, "like.json"),
      inserted_at: NaiveDateTime.to_iso8601(chat_comment.inserted_at) <> "Z"
    }
  end

  defp is_starred(comment, student_id) do
    case Repo.get_by(Star, chat_comment_id: comment.id, student_id: student_id) do
      nil -> false
      _ -> true
    end
  end
end
