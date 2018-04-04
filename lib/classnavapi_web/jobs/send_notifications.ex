defmodule ClassnavapiWeb.Jobs.SendNotifications do

  alias Classnavapi.Repo
  alias Classnavapi.Users.User
  alias Classnavapi.User.Device
  alias Classnavapi.Student
  alias Classnavapi.Class
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment
  alias ClassnavapiWeb.Notification
  alias Classnavapi.Assignments

  import Ecto.Query

  @assignment_reminder_today_category 100
  @assignment_reminder_tomorrow_category 200
  @assignment_reminder_future_category 300

  def run(time) do
    time 
    |> assignment_query(:today) 
    |> Enum.each(&send_notifications(&1, :today))

    time
    |> assignment_query(:future)
    |> Enum.each(&send_notifications(&1, :future))
  end

  defp assignment_query(time, atom) do
    {:ok, time} = Time.new(time.hour, time.minute, 0, 0)
    now = DateTime.utc_now() |> DateTime.to_date()

    from(student in Student)
    |> join(:inner, [student], sclass in StudentClass, student.id == sclass.student_id and sclass.is_notifications == true)
    |> join(:inner, [student, sclass], sassign in StudentAssignment, sassign.student_class_id == sclass.id and sassign.is_reminder_notifications == true)
    |> join(:inner, [student, sclass, sassign], class in Class, class.id == sclass.class_id)
    |> join(:inner, [student, sclass, sassign, class], user in User, user.student_id == student.id)
    |> join(:inner, [student, sclass, sassign, class, user], device in Device, user.id == device.user_id)
    |> where([student], student.notification_time == ^time)
    |> where([student], student.is_notifications == true and student.is_reminder_notifications == true)
    |> where([student, sclass, sassign], not(is_nil(sassign.due)) and sassign.is_completed == false)
    |> filter_due_date(now, atom)
    |> where([student, sclass], sclass.is_dropped == false)
    |> group_by([student, sclass, sassign, class, user, device], [device.udid, student.notification_days_notice])
    |> select([student, sclass, sassign, class, user, device], %{udid: device.udid, days: student.notification_days_notice, count: count(sassign.id)})
    |> Repo.all()
  end

  defp filter_due_date(query, date, :today) do
    query |> where([student, sclass, sassign], fragment("?::date", sassign.due) == ^date)
  end

  defp filter_due_date(query, date, :future) do
    query |> where([student, sclass, sassign], fragment("?::date", sassign.due) > ^date and fragment("?::date", sassign.due) <= date_add(^date, student.notification_days_notice, "day"))
  end

  defp send_notifications(assignment, atom) do
    Notification.create_notification(assignment.udid, get_message(assignment, atom), get_topic(atom, assignment.days).topic)
  end

  defp get_message(assignment, atom) do
    Assignments.get_assignment_reminder(assignment.count, get_topic(atom, assignment.days).id)
    |> String.replace("[num]", assignment.count |> to_string())
    |> String.replace("[days]", assignment.days |> to_string())
  end

  defp get_topic(:today, _days), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_today_category)
  defp get_topic(:future, 1), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_tomorrow_category)
  defp get_topic(:future, _days), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_future_category)
end