defmodule Skoller.Notifications do
  @moduledoc """
  Context module for notifications
  """

  alias Skoller.Repo
  alias Skoller.EmailTypes
  alias Skoller.Students.Student
  alias Skoller.Analytics.Classes, as: AnalyticsClasses
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.Schools.School
  alias Skoller.Users.User
  alias Skoller.Devices.Device
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Assignments.Assignment
  alias Skoller.ChatPosts.Star, as: PostStar
  alias Skoller.ChatComments.Star, as: CommentStar
  alias Skoller.ChatComments.Comment
  alias Skoller.Classes.EditableClasses
  alias Skoller.ClassStatuses.Classes, as: ClassStatusesClasses
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @class_complete_status 1400
  @class_start_id 400

  @doc """
  Gets devices where the students have not disabled notifications.

  ## Returns
  `[Skoller.Devices.Device]` or `[]`
  """
  def get_notification_enabled_devices() do
    from(d in Device)
    |> join(:inner, [d], u in User, on: d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, on: s.id == u.student_id)
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
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], stu in Student, on: stu.id == sc.student_id)
    |> join(:inner, [sc, stu], usr in User, on: usr.student_id == stu.id)
    |> join(:inner, [sc, stu, usr], class in subquery(EditableClasses.get_editable_classes_subquery()), on: sc.class_id == class.id)
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
    |> join(:inner, [d], u in User, on: d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, on: s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.student_id == s.id)
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
    |> join(:inner, [d], u in User, on: u.id == d.user_id)
    |> join(:inner, [d, u], s in Student, on: s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.student_id == s.id)
    |> join(:inner, [d, u, s, sc], a in Assignment, on: a.class_id == sc.class_id)
    |> join(:inner, [d, u, s, sc, a], sa in StudentAssignment, on: sa.assignment_id == a.id and sa.student_class_id == sc.id)
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
  `[%{udid: Skoller.Devices.Device.udid, type: Skoller.Devices.Device.type, days: Skoller.Students.Student.notification_days_notice, count: Integer}]` or `[]`
  """
  def get_assignment_reminders(time, atom) do
    {:ok, time} = Time.new(time.hour, time.minute, 0, 0)
    now = DateTime.utc_now() |> DateTime.to_date()

    from(student in Student)
    |> join(:inner, [student], sclass in StudentClass, on: student.id == sclass.student_id and sclass.is_notifications == true)
    |> join(:inner, [student, sclass], sassign in StudentAssignment, on: sassign.student_class_id == sclass.id and sassign.is_reminder_notifications == true)
    |> join(:inner, [student, sclass, sassign], user in User, on: user.student_id == student.id)
    |> join(:inner, [student, sclass, sassign, user], device in Device, on: user.id == device.user_id)
    |> where([student], student.is_notifications == true and student.is_reminder_notifications == true)
    |> where([student, sclass, sassign], not(is_nil(sassign.due)) and sassign.is_completed == false)
    |> filter_due_date(now, atom, time)
    |> where([student, sclass], sclass.is_dropped == false)
    |> group_by([student, sclass, sassign, user, device], [device.udid, device.type, student.notification_days_notice])
    |> select([student, sclass, sassign, user, device], %{udid: device.udid, type: device.type, days: student.notification_days_notice, count: count(sassign.id)})
    |> Repo.all()
  end

  @doc """
  Gets students that are attached to a class with notifications enabled

  ## Returns
  `[%{udid: Skoller.Devices.Device.udid, type: Skoller.Devices.Device.type, class_id: Skoller.Classes.Class.id}]` or `[]`
  """
  def get_class_start_notifications(class) do
    from(student_class in StudentClass)
    |> join(:left, [student_class], student in Student, on: student.id == student_class.student_id and student_class.class_id == ^class.id)
    |> join(:left, [student_class, student], user in User, on: user.student_id == student.id)
    |> join(:left, [student_class, student, user], device in Device, on: user.id == device.user_id)
    |> where([student_class, student, user, device], student_class.is_dropped == false and 
        student_class.is_notifications == true and 
        student.is_notifications == true and
        not is_nil(device.udid) and
        not is_nil(device.type) and
        device.type == "ios")
    |> select([student_class, student, user, device], %{udid: device.udid, type: device.type, class_id: student_class.class_id})
    |> Repo.all()
  end

  @doc """
  Gets classes that are due for class start notifications

  NOTE: Uses string based fragments written in raw POSTGRES to deal with aggregate functions not provided by the ORM

  ## Returns
  `[Skoller.Classes.Class]` or `[]`
  """
  def get_class_start_classes(day_of_week, time_interval) do
    switch = EmailTypes.get!(@class_start_id)
    if(switch.is_active_notification == true) do
      from(class in Class)
      |> join(:left, [class], class_period in ClassPeriod, on: class_period.id == class.class_period_id)
      |> join(:left, [class, class_period], school in School, on: class_period.school_id == school.id)
      |> join(:left, [class, class_period, school], active_students in subquery(AnalyticsClasses.get_student_classes_active_subquery()), on: class.id == active_students.class_id)
      |> where([class, class_period, school, active_students], class.class_status_id == @class_complete_status)
      |> where([class, class_period, school, active_students], active_students.active < 5)
      |> where(fragment("LEFT(meet_days, 1)=?", ^day_of_week))
      |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
      |> where(fragment("meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * ?) AT TIME ZONE timezone)::time", ^time_interval))
      |> Repo.all()
    else
      []
    end
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
    |> join(:inner, [s], stu in Student, on: stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, on: u.student_id == stu.id)
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
    |> join(:inner, [s], stu in Student, on: stu.id == s.student_id)
    |> join(:inner, [s, stu], u in User, on: u.student_id == stu.id)
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
    |> join(:inner, [s], c in Comment, on: c.chat_post_id == s.chat_post_id)
    |> join(:inner, [s, c], stu in Student, on: stu.id == s.student_id)
    |> join(:inner, [s, c, stu], u in User, on: u.student_id == stu.id)
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
    |> join(:inner, [u], s in Student, on: s.id == u.student_id)
    |> join(:inner, [u, s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.student_id == s.id)
    |> join(:inner, [u, s, sc], c in subquery(ClassStatusesClasses.need_syllabus_status_class_subquery()), on: c.id == sc.class_id)
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
    from(sc in subquery(EnrolledStudents.get_enrollment_by_class_id_subquery(class_id)))
    |> join(:inner, [sc], user in User, on: user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, on: stu.id == sc.student_id)
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
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], user in User, on: user.student_id == sc.student_id)
    |> join(:inner, [sc, user], stu in Student, on: stu.id == sc.student_id)
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