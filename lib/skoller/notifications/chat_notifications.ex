defmodule Skoller.ChatNotifications do
  @moduledoc """
  The context module for chat notifications.
  """

  alias Skoller.Repo
  alias Skoller.Students
  alias Skoller.Classes
  alias Skoller.Notifications
  alias SkollerWeb.Notification
  alias Skoller.Devices

  @class_chat_post "ClassChat.Post"
  @class_chat_comment "ClassChat.Comment"
  @class_chat_reply "ClassChat.Reply"

  @commented " commented on a post you follow."
  @commented_yours " commented on your post."
  @replied_yours " replied to your comment."
  @replied " replied to a comment you follow."
  @replied_post " replied in a post you follow"
  @posted_s " posted in "

  def send_new_post_notification(post, student_id) do
    student = Students.get_student_by_id!(student_id)
    class = Classes.get_class_by_id!(post.class_id)
    Notifications.get_class_chat_devices_by_class_id(student_id, post.class_id)
    |> Enum.each(&Notification.create_notification(&1.udid, build_chat_post_notification(post, student, class), @class_chat_post))
  end

  def send_new_comment_notification(comment, student_id) do
    comment = comment |> Repo.preload([:student, :chat_post])

    users = Notifications.get_notification_enabled_chat_post_users(student_id, comment.chat_post_id)
    |> Enum.map(&Map.put(&1, :msg, get_chat_message(&1, comment)))

    users 
    |> Enum.reduce([], &put_user_devices(&1) ++ &2)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.msg, @class_chat_comment))
  end

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
    |> Enum.each(&Notification.create_notification(&1.udid, &1.msg, @class_chat_reply))
  end

  defp build_chat_post_notification(post, student, class) do
    student.name_first <> " " <> student.name_last <> @posted_s <> class.name <> ": " <> post.post
  end

  defp get_chat_message(user, comment) do
    case user.student_id == comment.chat_post.student_id do
      false -> comment.student.name_first <> " " <> comment.student.name_last <> @commented
      true -> comment.student.name_first <> " " <> comment.student.name_last <> @commented_yours
    end
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