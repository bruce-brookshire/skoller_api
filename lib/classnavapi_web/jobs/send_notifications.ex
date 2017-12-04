defmodule ClassnavapiWeb.Jobs.SendNotifications do

  alias Classnavapi.Repo
  alias Classnavapi.User
  alias Classnavapi.User.Device
  alias Classnavapi.Student
  alias Classnavapi.Class
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment
  alias ClassnavapiWeb.Notification

  import Ecto.Query

  def run(time) do
    time 
    |> assignment_query() 
    |> Enum.each(&send_notifications(&1))
  end

  defp assignment_query(time) do
    {:ok, time} = Time.new(time.hour, time.minute, 0, 0)
    now = Date.utc_today()

    from(student in Student)
    |> join(:inner, [student], sclass in StudentClass, student.id == sclass.student_id and sclass.is_notifications == true)
    |> join(:inner, [student, sclass], sassign in StudentAssignment, sassign.student_class_id == sclass.id and sassign.is_notifications == true)
    |> join(:inner, [student, sclass, sassign], class in Class, class.id == sclass.class_id)
    |> join(:inner, [student, sclass, sassign, class], user in User, user.student_id == student.id)
    |> join(:inner, [student, sclass, sassign, class, user], device in Device, user.id == device.user_id)
    |> where([student], student.notification_time == ^time)
    |> where([student], student.is_notifications == true)
    |> where([student, sclass, sassign], sassign.due >= ^now and sassign.due <= date_add(^now, student.notification_days_notice, "day"))
    |> select([student, sclass, sassign, class, user, device], %{udid: device.udid, device_type: device.type, class_name: class.name, assign_name: sassign.name, assign_due: sassign.due})
    |> Repo.all()
  end

  defp send_notifications(assignment) do
    #Notification.create_notification(assignment.udid, format_msg(assignment))
  end

  defp format_msg(assignment) do
    assignment.assign_name <> " in " <> assignment.class_name <> " is due " <> due_days_away(assignment.assign_due) 
  end

  defp due_days_away(due) do
    today = Date.utc_today()
    case Date.diff(due, today) do
      0 -> "today."
      1 -> "tomorrow."
      days -> "in " <> to_string(days) <> " days."
    end
  end
end