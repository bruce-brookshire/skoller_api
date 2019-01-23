defmodule Skoller.ChatComments.Notifications do
  @moduledoc """
  A context module for notifications from chat comments.
  """

  alias Skoller.Notifications
  alias Skoller.Services.Notification
  alias Skoller.Repo
  alias Skoller.Devices

  @class_chat_comment "ClassChat.Comment"

  @commented " commented on a post you follow."
  @commented_yours " commented on your post."

  @doc """
  Sends a notification to all students in the class except for `student_id` that
  there is a new comment on a post.
  """
  def send_new_comment_notification(comment, student_id) do
    comment = comment |> Repo.preload([:student, :chat_post])

    users = Notifications.get_notification_enabled_chat_post_users(student_id, comment.chat_post_id)
    |> Enum.map(&Map.put(&1, :msg, get_chat_message(&1, comment)))

    users 
    |> Enum.reduce([], &put_user_devices(&1) ++ &2)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, &1.msg, @class_chat_comment, %{chat_post_id: comment.chat_post_id}))
  end

  defp get_chat_message(user, comment) do
    case user.student_id == comment.chat_post.student_id do
      false -> comment.student.name_first <> " " <> comment.student.name_last <> @commented
      true -> comment.student.name_first <> " " <> comment.student.name_last <> @commented_yours
    end
  end

  defp put_user_devices(user) do
    Devices.get_devices_by_user_id(user.id)
    |> Enum.map(&Map.put(&1, :msg, user.msg))
  end
end