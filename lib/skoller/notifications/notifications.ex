defmodule Skoller.Notifications do
  @moduledoc """
  Context module for notifications
  """

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Users.User
  alias Skoller.Devices.Device
  alias Skoller.Classes
  alias Skoller.Students
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Class.StudentClass
  alias Skoller.Class.Assignment
  alias Skoller.Chat.Post.Star, as: PostStar
  alias Skoller.Chat.Comment.Star, as: CommentStar
  alias Skoller.Chat.Comment

  import Ecto.Query

  @doc """
  Gets devices where the students have not disabled notifications.

  ## Returns
  `[Skoller.Devices.Device]` or `[]`
  """
  def get_notification_enabled_devices() do
    from(d in Device)
    |> join(:inner, [d], u in User, d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> where([d, u, s], s.is_notifications == true)
    |> distinct([d], d.udid)
    |> Repo.all()
  end

  @doc """
  Gets user and student from a student class for mod notifications.

  ## Notes
   * The class must be editable, and the student must be enrolled.

  ## Returns
  `%{user: Skoller.Users.User, student: Skoller.Students.Student}` or `nil`
  """
  def get_user_from_student_class(student_class_id) do
    from(sc in subquery(Students.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], stu in Student, stu.id == sc.student_id)
    |> join(:inner, [sc, stu], usr in User, usr.student_id == stu.id)
    |> join(:inner, [sc, stu, usr], class in subquery(Classes.get_editable_classes_subquery()), sc.class_id == class.id)
    |> where([sc, stu, usr], sc.id == ^student_class_id)
    |> where([sc, stu, usr], stu.is_notifications == true and stu.is_mod_notifications == true)
    |> select([sc, stu, usr], %{user: usr, student: stu})
    |> Repo.all
    |> List.first()
  end

  @doc """
  Gets devices from a class that have chat notifications enabled.

  ## Notes
   * The `student_id` does NOT get returned.

  ## Returns
  `[Skoller.Devices.Device]` or `[]`
  """
  def get_class_chat_devices_by_class_id(student_id, class_id) do
    from(d in Device)
    |> join(:inner, [d], u in User, d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == s.id)
    |> where([d, u, s], s.is_chat_notifications == true and s.is_notifications == true and s.id != ^student_id)
    |> where([d, u, s, sc], sc.class_id == ^class_id)
    |> Repo.all()
  end

  @doc """
  Gets devices from an assignment that have assignment post notifications enabled.

  ## Notes
   * The `student_id` does NOT get returned.

  ## Returns
  `[Skoller.Devices.Device]` or `[]`
  """
  def get_assignment_post_devices_by_assignment(student_id, assignment_id) do
    from(d in Device)
    |> join(:inner, [d], u in User, u.id == d.user_id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == s.id)
    |> join(:inner, [d, u, s, sc], a in Assignment, a.class_id == sc.class_id)
    |> join(:inner, [d, u, s, sc, a], sa in StudentAssignment, sa.assignment_id == a.id and sa.student_class_id == sc.id)
    |> where([d, u, s], s.id != ^student_id and s.is_notifications == true and s.is_assign_post_notifications == true)
    |> where([d, u, s, sc, a], a.id == ^assignment_id)
    |> where([d, u, s, sc, a, sa], sa.is_post_notifications == true)
    |> Repo.all()
  end

  @doc """
  Gets a list of assignments that are due for reminders.

  ## Notes
   * The atom can be either `:today` or `:future`
   * Will not return completed assignments

  ## Returns
  `[%{udid: Skoller.Devices.Device.udid, days: Skoller.Students.Student.notification_days_notice, count: Integer}]` or `[]`
  """
  def get_assignment_reminders(time, atom) do
    {:ok, time} = Time.new(time.hour, time.minute, 0, 0)
    now = DateTime.utc_now() |> DateTime.to_date()

    from(student in Student)
    |> join(:inner, [student], sclass in StudentClass, student.id == sclass.student_id and sclass.is_notifications == true)
    |> join(:inner, [student, sclass], sassign in StudentAssignment, sassign.student_class_id == sclass.id and sassign.is_reminder_notifications == true)
    |> join(:inner, [student, sclass, sassign], user in User, user.student_id == student.id)
    |> join(:inner, [student, sclass, sassign, user], device in Device, user.id == device.user_id)
    |> where([student], student.is_notifications == true and student.is_reminder_notifications == true)
    |> where([student, sclass, sassign], not(is_nil(sassign.due)) and sassign.is_completed == false)
    |> filter_due_date(now, atom, time)
    |> where([student, sclass], sclass.is_dropped == false)
    |> group_by([student, sclass, sassign, user, device], [device.udid, student.notification_days_notice])
    |> select([student, sclass, sassign, user, device], %{udid: device.udid, days: student.notification_days_notice, count: count(sassign.id)})
    |> Repo.all()
  end

  @doc """
  Gets users that are attached to a chat post with notifications enabled.

  ## Notes
   * The `student_id` does NOT get returned.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_notification_enabled_chat_post_users(student_id, chat_post_id) do
    from(s in PostStar)
    |> join(:inner, [s], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, u.student_id == stu.id)
    |> where([s], s.chat_post_id == ^chat_post_id and s.student_id != ^student_id)
    |> where([s, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> select([s, stu, u], u)
    |> Repo.all()
  end

  @doc """
  Gets users that are attached to a chat comment with notifications enabled.

  ## Notes
   * The `student_id` does NOT get returned.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_notification_enabled_chat_comment_users(student_id, chat_comment_id) do
    from(s in CommentStar)
    |> join(:inner, [s], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, u.student_id == stu.id)
    |> where([s], s.student_id != ^student_id)
    |> where([s], s.chat_comment_id == ^chat_comment_id)
    |> where([s, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> select([s, stu, u], u)
    |> Repo.all()
  end

  @doc """
  Gets users that are attached to a chat post with notifications enabled through a comment.

  ## Notes
   * The `student_id` does NOT get returned.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_notification_enabled_chat_post_users_by_comment(student_id, chat_comment_id) do
    from(s in PostStar)
    |> join(:inner, [s], c in Comment, c.chat_post_id == s.chat_post_id)
    |> join(:inner, [s, c], stu in Student, stu.id == s.student_id)
    |> join(:inner, [s, c, stu], u in User, u.student_id == stu.id)
    |> where([s], s.student_id != ^student_id)
    |> where([s, c], c.id == ^chat_comment_id)
    |> where([s, c, stu], stu.is_chat_notifications == true and stu.is_notifications == true)
    |> select([s, c, stu, u], u)
    |> Repo.all()
  end

  @doc """
  Gets user ids that in classes that need syllabi with notifications enabled.

  ## Returns
  `[Skoller.Users.User.id]` or `[]`
  """
  def get_notification_enabled_needs_syllabus_users() do
    from(u in User)
    |> join(:inner, [u], s in Student, s.id == u.student_id)
    |> join(:inner, [u, s], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == s.id)
    |> join(:inner, [u, s, sc], c in subquery(Classes.need_syllabus_status_class_subquery()), c.id == sc.class_id)
    |> where([u, s], s.is_notifications == true)
    |> distinct([u], u.id)
    |> Repo.all()
  end

  @doc """
  Gets users in a class with notifications enabled.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_users_from_class(class_id) do
    from(sc in subquery(Students.get_enrollment_by_class_id_subquery(class_id)))
    |> join(:inner, [sc], user in User, user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, stu.id == sc.student_id)
    |> where([sc, user, stu], stu.is_notifications == true)
    |> select([sc, user], user)
    |> Repo.all()
  end
  
  @doc """
  Gets enrolled users in a student class with notifications enabled.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_users_from_student_class(id) do
    from(sc in subquery(Students.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], user in User, user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, stu.id == sc.student_id)
    |> where([sc, user], sc.id == ^id)
    |> where([sc, user, stu], stu.is_notifications == true)
    |> select([sc, user], user)
    |> Repo.all
  end

  defp filter_due_date(query, date, :today, time) do
    query 
    |> where([student, sclass, sassign], fragment("?::date", sassign.due) == ^date)
    |> where([student], student.notification_time == ^time)
  end

  defp filter_due_date(query, date, :future, time) do
    query 
    |> where([student, sclass, sassign], fragment("?::date", sassign.due) > ^date and fragment("?::date", sassign.due) <= date_add(^date, student.notification_days_notice, "day"))
    |> where([student], student.future_reminder_notification_time == ^time)
  end
end