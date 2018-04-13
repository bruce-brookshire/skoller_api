defmodule Skoller.Notifications do

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.User
  alias Skoller.Classes
  alias Skoller.Students

  import Ecto.Query

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
end