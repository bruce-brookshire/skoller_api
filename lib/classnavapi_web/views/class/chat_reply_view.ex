defmodule ClassnavapiWeb.Class.ChatReplyView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChatReplyView

  def render("index.json", %{chat_replies: chat_replies}) do
    render_many(chat_replies, ChatReplyView, "chat_reply.json")
  end

  def render("show.json", %{chat_reply: chat_reply}) do
    render_one(chat_reply, ChatReplyView, "chat_reply.json")
  end

  def render("chat_reply.json", %{chat_reply: chat_reply}) do
    chat_reply = chat_reply |> Repo.preload([:student])
    %{
      reply: chat_reply.reply,
      student: render_one(chat_reply.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_reply.id
    }
  end

  def render("chat_reply_detail.json", %{chat_reply: chat_reply}) do
    chat_reply = chat_reply |> Repo.preload([:student, :likes])
    %{
      reply: chat_reply.reply,
      student: render_one(chat_reply.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_reply.id,
      likes: render_many(chat_reply.likes, LikeView, "like.json")
    }
  end
end
