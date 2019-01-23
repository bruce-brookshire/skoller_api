defmodule Skoller.ChatPosts.Notifications do
  @moduledoc """
  A context module for chat post notifications
  """

  alias Skoller.Students
  alias Skoller.Classes
  alias Skoller.Notifications
  alias Skoller.Services.Notification

  @class_chat_post "ClassChat.Post"

  @posted_s " posted in "

  @doc """
  Sends a notification to all students in the class except for `student_id` that
  there is a new post.
  """
  def send_new_post_notification(post, student_id) do
    student = Students.get_student_by_id!(student_id)
    class = Classes.get_class_by_id!(post.class_id)
    Notifications.get_class_chat_devices_by_class_id(student_id, post.class_id)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, build_chat_post_notification(post, student, class), @class_chat_post, %{chat_post_id: post.id}))
  end

  defp build_chat_post_notification(post, student, class) do
    student.name_first <> " " <> student.name_last <> @posted_s <> class.name <> ": " <> post.post
  end
end