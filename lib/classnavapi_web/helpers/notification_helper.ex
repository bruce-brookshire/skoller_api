defmodule ClassnavapiWeb.Helpers.NotificationHelper do
  
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Notification
  alias Classnavapi.Assignment.Mod.Action
  alias Classnavapi.Student
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.User
  alias Classnavapi.User.Device
  alias Classnavapi.Class
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Chat.Comment.Star, as: CommentStar
  alias Classnavapi.Chat.Post.Star, as: PostStar
  alias Classnavapi.Chat.Comment

  import Ecto.Query

  @moduledoc """
  
  Contains helper functions for sending notifications.

  """

  @class_complete_category "Class.Complete"
  @auto_update_category "Update.Auto"
  @pending_update_category "Update.Pending"
  @class_chat_comment "ClassChat.Comment"
  @class_chat_post "ClassChat.Post"
  @class_chat_reply "ClassChat.Reply"
  @manual_syllabus_category "Manual.NeedsSyllabus"
  @manual_custom_category "Manual.Custom"

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @syllabus_status 200

  @a_classmate_has "A classmate has "
  @you_have "You have "
  @updates_pending " updates pending"
  @of_s " of "
  @to_s " to "
  @the_s " the "
  @in_s " in "
  @and_s " and "
  @c_and_s ", and "
  @updated "updated"
  @added "added "
  @removed "removed "
  @due "due "
  @due_date "due date"
  @notification_end "."
  @no_weight "no weight"

  @class_complete "We didn't find any assignments on the syllabus. Be sure to add assignments on the app throughout the semester so you and your classmates can keep up. 💯"
  @we_created "We created"
  @from_syllabus "from the class syllabus. Any new assignments or schedule changes are up to you and your classmates. 💯"
  @one_assign_class_complete "assignment " <> @from_syllabus
  @multiple_assign_class_complete "assignments " <> @from_syllabus

  @auto_delete "Assignment has been removed"
  @auto_add "Assignment has been added"
  @auto_update " has been autoupdated"
  #@of_class_accepted "% of your classmates have made this change."

  @is_ready " is ready!"

  @commented " commented on a post you follow."
  @commented_yours " commented on your post."
  @replied_yours " replied to your comment."
  @replied " replied to a comment you follow."
  @replied_post " replied in a post you follow"
  @posted_s " posted in "

  @needs_syllabus_msg "It’s not too late to upload your syllabi on our website! Take a couple minutes to knock it out. Your class will love you for it 👌"

  def send_mod_update_notifications({:ok, %Action{} = action}) do
    user = get_user_from_student_class(action.student_class_id)
    devices = user.user |> get_user_devices()
    case devices do
      [] -> :ok
      _ -> action |> build_notifications(user, devices)
    end
  end

  def send_mod_update_notifications({:ok, %{actions: _} = mod}) do
    send_mod_update_notifications(mod)
  end

  def send_mod_update_notifications(mod) when is_list(mod) do
    mod |> Enum.each(&send_mod_update_notifications(&1))
  end

  def send_mod_update_notifications(%{actions: nil}), do: nil
  def send_mod_update_notifications({:ok, _}), do: nil
  def send_mod_update_notifications(mod) do
    mod.actions |> Enum.each(&send_mod_update_notifications(&1))
  end

  def get_user_devices(%User{} = user) do
    from(dev in Device)
    |> join(:inner, [dev], user in User, user.id == dev.user_id)
    |> where([dev, user], user.id == ^user.id)
    |> Repo.all
  end

  def send_class_complete_notification(%Class{is_editable: true} = class) do
    users = class 
            |> get_users_from_class()
    devices = users |> Enum.reduce([], &get_user_devices(&1) ++ &2)
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
    class = mod |> get_class_from_mod()
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
        users = get_users_from_student_class(action.student_class_id)
        devices = users |> Enum.reduce([], &get_user_devices(&1) ++ &2)
        devices |> Enum.each(&Notification.create_notification(&1.udid, %{title: title, body: body}, @auto_update_category))
      false -> 
        :ok
    end
  end
  def build_auto_update_notification(_), do: nil

  def send_new_post_notification(post, student_id) do
    from(d in Device)
    |> join(:inner, [d], u in User, d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in StudentClass, sc.student_id == s.id)
    |> join(:inner, [d, u, s, sc], c in Class, c.id == sc.class_id)
    |> where([d, u, s], s.is_chat_notifications == true and s.is_notifications == true and s.id != ^student_id)
    |> where([d, u, s, sc], sc.is_dropped == false)
    |> where([d, u, s, sc, c], c.id == ^post.class_id)
    |> Repo.all()
    |> Enum.each(&Notification.create_notification(&1.udid, build_chat_post_notification(post, student_id), @class_chat_post))
  end

  def send_new_comment_notification(comment, student_id) do
    comment = comment |> Repo.preload([:student, :chat_post])

    users = from(s in PostStar)
    |> join(:inner, [s], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, u.student_id == stu.id)
    |> where([s], s.chat_post_id == ^comment.chat_post_id and s.student_id != ^student_id)
    |> where([s, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> select([s, stu, u], u)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :msg, get_chat_message(&1, comment)))

    users 
    |> Enum.reduce([], &put_user_devices(&1) ++ &2)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.msg, @class_chat_comment))
  end

  def send_new_reply_notification(reply, student_id) do
    reply = reply |> Repo.preload([:student, :chat_comment])

    comment_users = from(s in CommentStar)
    |> join(:inner, [s], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, u.student_id == stu.id)
    |> where([s], s.student_id != ^student_id)
    |> where([s], s.chat_comment_id == ^reply.chat_comment_id)
    |> where([s, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> select([s, stu, u], u)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :msg, get_chat_reply_msg(&1, reply)))

    user_ids = comment_users |> List.foldl([], &List.wrap(&1.id) ++ &2)

    post_users = from(s in PostStar)
    |> join(:inner, [s], c in Comment, c.chat_post_id == s.chat_post_id)
    |> join(:inner, [s, c], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, c, stu], u in User, u.student_id == stu.id)
    |> where([s], s.student_id != ^student_id)
    |> where([s, c], c.id == ^reply.chat_comment_id)
    |> where([s, c, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> where([s, c, stu, u], u.id not in ^user_ids)
    |> select([s, c, stu, u], u)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :msg, reply.student.name_first <> " " <> reply.student.name_last <> @replied_post))

    users = post_users ++ comment_users

    users 
    |> Enum.reduce([], &put_user_devices(&1) ++ &2)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.msg, @class_chat_reply))
  end

  def send_needs_syllabus_notifications() do
    users = from(u in User)
    |> join(:inner, [u], s in Student, s.id == u.student_id)
    |> join(:inner, [u, s], sc in StudentClass, sc.student_id == s.id)
    |> join(:inner, [u, s, sc], c in Class, c.id == sc.class_id)
    |> where([u, s], s.is_notifications == true)
    |> where([u, s, sc], sc.is_dropped == false)
    |> where([u, s, sc, c], c.class_status_id == @syllabus_status)
    |> distinct([u], u.id)
    |> Repo.all()
    |> Enum.reduce([], &get_user_devices(&1) ++ &2)

    Repo.insert(%Classnavapi.Notification.ManualLog{affected_users: Enum.count(users), notification_category: @manual_syllabus_category, msg: @needs_syllabus_msg})

    users
    |> Enum.each(&Notification.create_notification(&1.udid, @needs_syllabus_msg, @manual_syllabus_category))
  end

  def send_custom_notification(msg) do
    users = from(u in User)
    |> join(:inner, [u], s in Student, s.id == u.student_id)
    |> join(:inner, [u, s], d in Device, d.user_id == u.id)
    |> where([u, s], s.is_notifications == true)
    |> distinct([u, s, d], d.udid)
    |> select([u, s, d], d)
    |> Repo.all()

    Repo.insert(%Classnavapi.Notification.ManualLog{affected_users: Enum.count(users), notification_category: @manual_custom_category, msg: msg})
  
    users
    |> Enum.each(&Notification.create_notification(&1.udid, msg, @manual_custom_category))
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

  defp build_chat_post_notification(post, student_id) do
    student = Repo.get!(Student, student_id)
    class = Repo.get!(Class, post.class_id)
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
    from(dev in Device)
    |> join(:inner, [dev], user in User, user.id == dev.user_id)
    |> where([dev, user], user.id == ^user.id)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :msg, user.msg))
  end

  defp class_complete_msg(assignments) do
    case Enum.count(assignments) do
      0 -> @class_complete
      1 -> @we_created <> " 1 " <> @one_assign_class_complete
      num -> @we_created <> " " <> to_string(num) <> " " <> @multiple_assign_class_complete
    end
  end

  defp get_users_from_class(%Class{} = class) do
    from(sc in StudentClass)
    |> join(:inner, [sc], user in User, user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, stu.id == sc.student_id)
    |> where([sc, user], sc.class_id == ^class.id and sc.is_dropped == false)
    |> where([sc, user, stu], stu.is_notifications == true)
    |> select([sc, user], user)
    |> Repo.all
  end

  defp get_users_from_student_class(id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], user in User, user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, stu.id == sc.student_id)
    |> where([sc, user], sc.id == ^id and sc.is_dropped == false)
    |> where([sc, user, stu], stu.is_notifications == true)
    |> select([sc, user], user)
    |> Repo.all
  end

  defp build_notifications(%Action{} = action, %{student: student}, devices) do
    count = get_pending_mods_for_student(student.id)
    msg = case count do
      1 -> action |> one_pending_mod_notification()
      num -> student |> multiple_pending_mod_notification(num)
    end
    devices |> Enum.each(&Notification.create_notification(&1.udid, msg, @pending_update_category))
  end

  defp one_pending_mod_notification(action) do
    mod = get_mod_from_action(action) |> Repo.preload(:assignment)
    class = mod |> get_class_from_mod()
    cond do
      mod.assignment_mod_type_id == @new_assignment_mod -> @a_classmate_has <> @added <> mod_add_notification_text(mod, class)
      mod.assignment_mod_type_id == @delete_assignment_mod -> @a_classmate_has <> @removed <> mod_delete_notification_text(mod, class)
      is_nil(mod.data["due"]) -> @a_classmate_has <> @removed <> @the_s <> @due_date <> @of_s <> class_and_assign_name(mod, class)
      true -> @a_classmate_has <> @updated <> @the_s <> mod_change_notification_text(mod, class)
    end
  end

  defp multiple_pending_mod_notification(student, num) do
    @you_have <> to_string(num) <> @updates_pending <> @in_s <> class_list(student) <> @notification_end
  end

  defp mod_add_notification_text(mod, class) do
    case mod.assignment.due do
      nil ->
        mod.assignment.name <> @in_s <> class.name <> @notification_end
      due ->
        mod.assignment.name <> @in_s <> class.name <> ", " <> @due <> format_date(due) <> @notification_end
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

  defp class_list(%Student{} = student) do
    from(class in Class)
    |> join(:inner, [class], sc in StudentClass, sc.class_id == class.id)
    |> join(:inner, [class, sc], act in Action, act.student_class_id == sc.id)
    |> where([class, sc, act], is_nil(act.is_accepted))
    |> where([class, sc, act], sc.student_id == ^student.id)
    |> select([class, sc, act], class)
    |> Repo.all
    |> Enum.uniq
    |> format_list
  end

  defp format_list(list) do
    head = list |> List.first()
    tail = list |> List.last()
    case list |> Enum.count() do
      1 -> head.name
      2 -> head.name <> @and_s <> tail.name
      _ -> str = list |> List.delete_at(-1)
                      |> List.delete_at(0)
                      |> List.foldl(@c_and_s <> tail.name, & ", " <> &1.name <> &2)
        head.name <> str
    end
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

  defp get_pending_mods_for_student(student_id) do
    from(act in Action)
    |> join(:inner, [act], sc in StudentClass, sc.id == act.student_class_id)
    |> join(:inner, [act, sc], stu in Student, stu.id == sc.student_id)
    |> where([act], is_nil(act.is_accepted))
    |> where([act, sc, stu], stu.id == ^student_id)
    |> select([act, sc, stu], count(act.id))
    |> Repo.all
    |> List.first
  end

  defp get_user_from_student_class(student_class_id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], stu in Student, stu.id == sc.student_id)
    |> join(:inner, [sc, stu], usr in User, usr.student_id == stu.id)
    |> join(:inner, [sc, stu, usr], class in Class, sc.class_id == class.id)
    |> where([sc, stu, usr], sc.id == ^student_class_id and sc.is_dropped == false)
    |> where([sc, stu, usr], stu.is_notifications == true and stu.is_mod_notifications == true)
    |> where([sc, stu, usr, class], class.is_editable == true)
    |> select([sc, stu, usr], %{user: usr, student: stu})
    |> Repo.all
    |> List.first()
  end

  defp get_mod_from_action(%Action{} = action) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id)
    |> where([mod, act], act.id == ^action.id)
    |> Repo.all
    |> List.first()
  end

  defp get_class_from_mod(%Mod{} = mod) do
    from(class in Class)
    |> join(:inner, [class], assign in Assignment, class.id == assign.class_id)
    |> where([class, assign], assign.id == ^mod.assignment_id)
    |> Repo.all
    |> List.first()
  end

  defp get_weight_from_id(nil), do: @no_weight

  defp get_weight_from_id(id) do
    weight = Repo.get!(Weight, id)
    weight.name
  end

  defp format_date(date) do
    day_of_week = get_day_of_week(Date.day_of_week(date))
    month = get_month(date.month)
    day = get_day(date.day)
    day_of_week <> ", " <> month <> " " <> day
  end

  defp format_date_from_iso(date) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    
    date |> format_date()
  end

  defp get_month(1), do: "January"
  defp get_month(2), do: "February"
  defp get_month(3), do: "March"
  defp get_month(4), do: "April"
  defp get_month(5), do: "May"
  defp get_month(6), do: "June"
  defp get_month(7), do: "July"
  defp get_month(8), do: "August"
  defp get_month(9), do: "September"
  defp get_month(10), do: "October"
  defp get_month(11), do: "November"
  defp get_month(12), do: "December"

  defp get_day(1), do: "1st"
  defp get_day(2), do: "2nd"
  defp get_day(3), do: "3rd"
  defp get_day(21), do: "21st"
  defp get_day(22), do: "22nd"
  defp get_day(23), do: "23rd"
  defp get_day(31), do: "31st"
  defp get_day(day), do: to_string(day) <> "th"

  defp get_day_of_week(1), do: "Monday"
  defp get_day_of_week(2), do: "Tuesday"
  defp get_day_of_week(3), do: "Wednesday"
  defp get_day_of_week(4), do: "Thursday"
  defp get_day_of_week(5), do: "Friday"
  defp get_day_of_week(6), do: "Saturday"
  defp get_day_of_week(7), do: "Sunday"
end