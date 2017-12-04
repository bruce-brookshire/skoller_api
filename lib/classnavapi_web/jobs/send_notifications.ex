defmodule ClassnavapiWeb.Jobs.SendNotifications do

  alias Classnavapi.Repo
  alias Classnavapi.Student
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment

  import Ecto.Query

  def run(time) do
    time 
    |> assignment_query() 
    |> send_notifications()
  end

  defp assignment_query(time) do
    {:ok, time} = Time.new(time.hour, time.minute, 0, 0)
    now = Date.utc_today()

    from(student in Student)
    |> join(:inner, [student], sclass in StudentClass, student.id == sclass.student_id and sclass.is_notifications == true)
    |> join(:inner, [student, sclass], sassign in StudentAssignment, sassign.student_class_id == sclass.id and sassign.is_notifications == true)
    |> where([student], student.notification_time == ^time)
    |> where([student], student.is_notifications == true)
    |> where([student, sclass, sassign], sassign.due >= ^now and sassign.due <= date_add(^now, student.notification_days_notice, "day"))
    |> select([student, sclass, sassign], %{student: student, class: sclass, assign_name: sassign.name, assign_due: sassign.due})
    |> Repo.all()
  end

  defp send_notifications(assignments) do
    
  end
end