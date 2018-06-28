defmodule SkollerWeb.Helpers.NotificationHelper do
  
  alias Skoller.Repo
  alias SkollerWeb.Notification
  alias Skoller.Students.Student
  alias Skoller.Assignment.Mod
  alias Skoller.Class.Assignment
  alias Skoller.Classes
  alias Skoller.Mods
  alias Skoller.Notifications
  alias Skoller.Devices
  alias Skoller.Dates

  @moduledoc """
  
  Contains helper functions for sending notifications.

  """

  @class_complete_category "Class.Complete"
  @auto_update_category "Update.Auto"
  @class_chat_comment "ClassChat.Comment"
  @class_chat_post "ClassChat.Post"
  @class_chat_reply "ClassChat.Reply"
  @manual_syllabus_category "Manual.NeedsSyllabus"
  @manual_custom_category "Manual.Custom"
  @assignment_post "Assignment.Post"

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @of_s " of "
  @to_s " to "
  @in_s " in "
  @removed "removed "
  @due "due "
  @notification_end "."
  @no_weight "no weight"

  @class_complete "We didn't find any assignments on the syllabus. Be sure to add assignments on the app throughout the semester so you and your classmates can keep up. 💯"
  @we_created "We created"
  @from_syllabus "from the class syllabus. Any new assignments or schedule changes are up to you and your classmates. 💯"
  @one_assign_class_complete "assignment " <> @from_syllabus
  @multiple_assign_class_complete "assignments " <> @from_syllabus

  @auto_delete "Autoupdate: assignment has been removed"
  @auto_add "Autoupdate: assignment has been added"
  @auto_update " has been autoupdated"
  #@of_class_accepted "% of your classmates have made this change."

  @is_ready " is ready!"

  @commented " commented on a post you follow."
  @commented_yours " commented on your post."
  @replied_yours " replied to your comment."
  @replied " replied to a comment you follow."
  @replied_post " replied in a post you follow"
  @posted_s " posted in "

  @commented_on_s " commented on "

  @needs_syllabus_msg "It’s not too late to upload your syllabi on our website! Take a couple minutes to knock it out. Your class will love you for it 👌"

  def send_class_complete_notification(%{is_editable: true} = class) do
    devices = class.id
            |> Notifications.get_users_from_class()
            |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)
    class = class |> Repo.preload([:assignments])
    msg = class.assignments |> class_complete_msg()
    
    devices |> Enum.each(&Notification.create_notification(&1.udid, %{title: class.name <> @is_ready, body: msg}, @class_complete_category))
  end
  def send_class_complete_notification(_class), do: :ok

  def send_auto_update_notification(actions) do
    actions |> Enum.each(&build_auto_update_notification(&1))
  end

  def build_auto_update_notification({:ok, action}) do
    mod = Repo.get(Mod, action.assignment_modification_id)
          |> Repo.preload(:assignment)
    class = Mods.get_class_from_mod_id(mod.id)
    case class.is_editable do
      true -> 
        title = case mod.assignment_mod_type_id do
          @new_assignment_mod -> @auto_add
          @delete_assignment_mod -> @auto_delete
          _ -> mod.assignment.name <> @auto_update
        end
        body = case mod.assignment_mod_type_id do
          @new_assignment_mod -> mod_add_notification_text(mod, class)
          @delete_assignment_mod -> mod_delete_notification_text(mod, class)
          _ -> text = mod_change_notification_text(mod, class)
          len = text |> String.length
          msg = text |> String.slice(0..0) |> String.upcase()
          msg <> (text |> String.slice(1..len))
        end
        Notifications.get_users_from_student_class(action.student_class_id)
        |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)
        |> Enum.each(&Notification.create_notification(&1.udid, %{title: title, body: body}, @auto_update_category))
      false -> 
        :ok
    end
  end
  def build_auto_update_notification(_), do: nil

  def send_new_post_notification(post, student_id) do
    student = Repo.get!(Student, student_id)
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

  def send_needs_syllabus_notifications() do
    users = Notifications.get_notification_enabled_needs_syllabus_users()
    |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)

    Repo.insert(%Skoller.Notification.ManualLog{affected_users: Enum.count(users), notification_category: @manual_syllabus_category, msg: @needs_syllabus_msg})

    users
    |> Enum.each(&Notification.create_notification(&1.udid, @needs_syllabus_msg, @manual_syllabus_category))
  end

  def send_custom_notification(msg) do
    devices = Notifications.get_notification_enabled_devices()

    Repo.insert(%Skoller.Notification.ManualLog{affected_users: Enum.count(devices), notification_category: @manual_custom_category, msg: msg})
  
    devices
    |> Enum.each(&Notification.create_notification(&1.udid, msg, @manual_custom_category))
  end

  def send_assignment_post_notification(post, student_id) do
    student = Repo.get!(Student, student_id)
    assignment = Repo.get!(Assignment, post.assignment_id)
    class = Classes.get_class_by_id!(assignment.class_id)
    Notifications.get_assignment_post_devices_by_assignment(student_id, post.assignment_id)
    |> Enum.each(&Notification.create_notification(&1.udid, build_assignment_post_msg(post, student, assignment, class), @assignment_post))
  end

  # defp add_acceptance_percentage(mod) do
  #   actions = from(act in Action)
  #   |> join(:inner, [act], mod in Mod, act.assignment_modification_id == mod.id)
  #   |> where([act, mod], mod.id == ^mod.id)
  #   |> Repo.all()

  #   count = actions |> Enum.count()

  #   accepted = actions |> Enum.count(& &1.is_accepted == true)

  #   (accepted / count) * 100 |> Kernel.round()
  # end

  defp build_chat_post_notification(post, student, class) do
    student.name_first <> " " <> student.name_last <> @posted_s <> class.name <> ": " <> post.post
  end
  
  defp build_assignment_post_msg(post, student, assignment, class) do
    student.name_first <> " " <> student.name_last <> @commented_on_s <> assignment.name <> @in_s <> class.name <> ": " <> post.post
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

  defp class_complete_msg(assignments) do
    case Enum.count(assignments) do
      0 -> @class_complete
      1 -> @we_created <> " 1 " <> @one_assign_class_complete
      num -> @we_created <> " " <> to_string(num) <> " " <> @multiple_assign_class_complete
    end
  end

  defp mod_add_notification_text(mod, class) do
    case mod.assignment.due do
      nil ->
        mod.assignment.name <> @in_s <> class.name <> @notification_end
      due ->
        mod.assignment.name <> @in_s <> class.name <> ", " <> @due <> Dates.format_date(due) <> @notification_end
    end
  end

  defp mod_change_notification_text(%{data: %{due: nil}} = mod, class) do
    @removed <> " " <> mod_type(mod) <> @of_s <> class_and_assign_name(mod, class)
  end
  defp mod_change_notification_text(mod, class) do
    mod_type(mod) <> @of_s <> class_and_assign_name(mod, class) <> @to_s <> mod_change(mod) <> @notification_end
  end

  defp class_and_assign_name(mod, class) do
    class.name <> " " <> mod.assignment.name
  end

  defp mod_delete_notification_text(mod, class) do
    mod.assignment.name <> @in_s <> class.name <> @notification_end
  end

  defp mod_type(%Mod{assignment_mod_type_id: type}) do
    case type do
      @name_assignment_mod -> "name"
      @weight_assignment_mod -> "weight"
      @due_assignment_mod -> "due date"
    end
  end

  defp mod_change(%Mod{assignment_mod_type_id: type, data: data}) do
    case type do
      @name_assignment_mod -> data["name"]
      @weight_assignment_mod -> get_weight_from_id(data["weight_id"])
      @due_assignment_mod -> format_date_from_iso(data["due"])
    end
  end

  defp get_weight_from_id(nil), do: @no_weight

  defp get_weight_from_id(id) do
    weight = Repo.get!(Weight, id)
    weight.name
  end

  defp format_date_from_iso(date) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    
    date |> Dates.format_date()
  end
end