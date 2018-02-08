defmodule ClassnavapiWeb.Student.InboxView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Student.InboxView
  alias ClassnavapiWeb.Class.ChatPostView
  alias ClassnavapiWeb.Student.Inbox.ResponseView

  def render("index.json", %{inbox: inbox, current_student_id: current_student_id}) do
    render_many(inbox, InboxView, "inbox.json", %{current_student_id: current_student_id})
  end

  def render("inbox.json", %{inbox: %{chat_post: chat_post, star: star, color: color, response: response}, current_student_id: student_id}) do
    %{
      chat_post: %{
        id: chat_post.id,
        post: chat_post.post
      },
      color: color,
      response: render_one(response, ResponseView, "response.json")
    }
  end

  def render("inbox.json", %{inbox: %{chat_comment: chat_comment, star: star, color: color, parent_post: parent, reply: r}, current_student_id: student_id}) do
    %{
      chat_post: render_one(parent, ChatPostView, "chat_post_detail.json", %{current_student_id: student_id})
    }
  end
end