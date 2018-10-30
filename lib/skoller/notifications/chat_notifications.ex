defmodule Skoller.ChatNotifications do
  @moduledoc """
  The context module for chat notifications.
  """

  alias Skoller.Repo
  alias Skoller.Notifications
  alias Skoller.Services.Notification
  alias Skoller.Devices

  @class_chat_reply "ClassChat.Reply"

  @replied_yours " replied to your comment."
  @replied " replied to a comment you follow."
  @replied_post " replied in a post you follow"

  def send_new_reply_notification(reply, student_id) do
    reply = reply |> Repo.preload([:student, :chat_comment])

    comment_users = Notifications.get_notification_enabled_chat_comment_users(student_id, reply.chat_comment_id)
    |> Enum.map(&Map.put(&1, :msg, get_chat_reply_msg(&1, reply)))

    user_ids = comment_users |> List.foldl([], &List.wrap(&1.id) ++ &2)

    post_users = Notifications.get_notification_enabled_chat_post_users_by_comment(student_id, reply.chat_comment_id)
    |> Enum.filter(& &1.id not in user_ids)
    |> Enum.map(&Map.put(&1, :msg, reply.student.name_first <> " " <> reply.student.name_last <> @replied_post))

    users = post_users ++ comment_users

    users 
    |> Enum.reduce([], &put_user_devices(&1) ++ &2)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, &1.msg, @class_chat_reply))
  end

  defp get_chat_reply_msg(user, reply) do
    case user.student_id == reply.chat_comment.student_id do
      false -> reply.student.name_first <> " " <> reply.student.name_last <> @replied
      true -> reply.student.name_first <> " " <> reply.student.name_last <> @replied_yours
    end
  end

  defp put_user_devices(user) do
    Devices.get_devices_by_user_id(user.id)
    |> Enum.map(&Map.put(&1, :msg, user.msg))
  end
end