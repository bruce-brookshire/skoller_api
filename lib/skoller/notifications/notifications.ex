defmodule Skoller.Notifications do

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Users.User
  alias Skoller.Devices.Device
  alias Skoller.Classes
  alias Skoller.Students
  alias Skoller.Class.StudentAssignment
  alias Skoller.Class.StudentClass
  alias Skoller.Class.Assignment

  import Ecto.Query

  def get_notification_enabled_devices() do
    from(d in Device)
    |> join(:inner, [d], u in User, d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> where([d, u, s], s.is_notifications == true)
    |> distinct([d], d.udid)
    |> Repo.all()
  end

  def get_user_from_student_class(student_class_id) do
    from(sc in Students.get_enrolled_student_classes_subquery())
    |> join(:inner, [sc], stu in Student, stu.id == sc.student_id)
    |> join(:inner, [sc, stu], usr in User, usr.student_id == stu.id)
    |> join(:inner, [sc, stu, usr], class in subquery(Classes.get_editable_classes_subquery()), sc.class_id == class.id)
    |> where([sc, stu, usr], sc.id == ^student_class_id)
    |> where([sc, stu, usr], stu.is_notifications == true and stu.is_mod_notifications == true)
    |> select([sc, stu, usr], %{user: usr, student: stu})
    |> Repo.all
    |> List.first()
  end

  def get_class_chat_devices_by_class_id(student_id, class_id) do
    from(d in Device)
    |> join(:inner, [d], u in User, d.user_id == u.id)
    |> join(:inner, [d, u], s in Student, s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == s.id)
    |> where([d, u, s], s.is_chat_notifications == true and s.is_notifications == true and s.id != ^student_id)
    |> where([d, u, s, sc], sc.class_id == ^class_id)
    |> Repo.all()
  end

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