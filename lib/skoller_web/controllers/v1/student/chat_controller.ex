defmodule SkollerWeb.Api.V1.Student.ChatController do
  use SkollerWeb, :controller

  alias SkollerWeb.Class.ChatPostView
  alias SkollerWeb.Student.InboxView
  alias Skoller.Chats

  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def chat(conn, %{"student_id" => student_id} = params) do
    posts = Chats.get_student_chat(student_id, params)
    render(conn, ChatPostView, "index.json", %{chat_posts: posts, current_student_id: student_id})
  end

  def inbox(conn, %{"student_id" => student_id}) do
    inbox = Chats.get_chat_notifications(student_id)

    render(conn, InboxView, "index.json", %{inbox: inbox, current_student_id: student_id})
  end
end