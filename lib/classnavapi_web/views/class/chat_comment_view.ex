defmodule ClassnavapiWeb.Class.ChatCommentView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChatCommentView
  alias ClassnavapiWeb.Class.ChatReplyView

  def render("index.json", %{chat_comments: chat_comments}) do
    render_many(chat_comments, ChatCommentView, "chat_comment.json")
  end

  def render("show.json", %{chat_comment: chat_comment}) do
    render_one(chat_comment, ChatCommentView, "chat_comment.json")
  end

  def render("chat_comment.json", %{chat_comment: chat_comment}) do
    chat_comment = chat_comment |> Repo.preload([:student, :chat_replies])
    %{
      comment: chat_comment.comment,
      student: render_one(chat_comment.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_comment.id,
      replies: render_many(chat_comment.chat_replies, ChatReplyView, "chat_reply.json")
    }
  end

  def render("chat_comment_detail.json", %{chat_comment: chat_comment}) do
    chat_comment = chat_comment |> Repo.preload([:student, :chat_replies, :likes])
    %{
      comment: chat_comment.comment,
      student: render_one(chat_comment.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_comment.id,
      replies: render_many(chat_comment.chat_replies, ChatReplyView, "chat_reply.json"),
      likes: Enum.count(chat_comment.likes)
    }
  end
end
