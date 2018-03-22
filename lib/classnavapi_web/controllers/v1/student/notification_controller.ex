defmodule ClassnavapiWeb.Api.V1.Student.NotificationController do
  use ClassnavapiWeb, :controller

  alias ClassnavapiWeb.Student.InboxView
  alias Classnavapi.Chats.Chat

  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def notifications(conn, %{"student_id" => student_id}) do
    inbox = Chat.get_chat_notifications(student_id)

    render(conn, InboxView, "index.json", %{inbox: inbox, current_student_id: student_id})
  end
end