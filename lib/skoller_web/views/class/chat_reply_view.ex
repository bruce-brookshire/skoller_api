defmodule SkollerWeb.Class.ChatReplyView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.ChatReplyView
  alias SkollerWeb.Class.Chat.LikeView
  alias Skoller.Chats

  def render("index.json", %{chat_replies: chat_replies}) do
    render_many(chat_replies, ChatReplyView, "chat_reply.json")
  end

  def render("show.json", %{chat_reply: chat_reply, current_student_id: current_student_id}) do
    render_one(chat_reply, ChatReplyView, "chat_reply_detail.json", %{current_student_id: current_student_id})
  end

  def render("show.json", %{chat_reply: chat_reply}) do
    render_one(chat_reply, ChatReplyView, "chat_reply_detail.json")
  end

  def render("chat_reply.json", %{chat_reply: chat_reply}) do
    chat_reply = chat_reply |> Repo.preload([:student])
    %{
      reply: chat_reply.reply,
      student: render_one(chat_reply.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_reply.id,
      inserted_at: chat_reply.inserted_at
    }
  end

  def render("chat_reply_detail.json", %{chat_reply: chat_reply, current_student_id: student_id}) do
    chat_reply = chat_reply |> Repo.preload([:student, :likes])
    %{
      reply: chat_reply.reply,
      student: render_one(chat_reply.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_reply.id,
      likes: render_many(chat_reply.likes, LikeView, "like.json"),
      is_liked: chat_reply |> Chats.is_liked(student_id),
      inserted_at: chat_reply.inserted_at
    }
  end

  def render("chat_reply_detail.json", %{chat_reply: chat_reply}) do
    chat_reply = chat_reply |> Repo.preload([:student, :likes])
    %{
      reply: chat_reply.reply,
      student: render_one(chat_reply.student, SkollerWeb.StudentView, "student-short.json"),
      id: chat_reply.id,
      likes: render_many(chat_reply.likes, LikeView, "like.json"),
      inserted_at: chat_reply.inserted_at
    }
  end
end
