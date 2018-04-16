defmodule Skoller.Notifications do

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Users.User
  alias Skoller.Devices.Device
  alias Skoller.Classes
  alias Skoller.Students
  alias Skoller.Class.StudentAssignment
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
end