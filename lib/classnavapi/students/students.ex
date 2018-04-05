defmodule Classnavapi.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class
  alias Classnavapi.Schools.School
  alias Classnavapi.Schools.ClassPeriod
  alias Classnavapi.Student

  import Ecto.Query

  @doc """
  Returns the count of students in a given `Classnavapi.Schools.ClassPeriod`.

  ## Examples

      iex> val = Classnavapi.Students.get_student_count_by_period(1)
      ...>Kernel.is_integer(val)
      true

  """
  def get_student_count_by_period(period_id) do
    from(sc in subquery(get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> where([sc, c], c.class_period_id == ^period_id)
    |> distinct([sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_school_hub_data() do
    from(school in School)
    |> join(:left, [school], student in subquery(get_school_enrollment_subquery()), student.school_id == school.id)
    |> select([school, student], %{school: school, students: student.count})
    |> Repo.all()
  end

  defp get_school_enrollment_subquery() do
    from(student in Student)
    |> join(:inner, [student], sc in subquery(get_enrolled_student_classes_subquery()), sc.student_id == student.id)
    |> join(:inner, [student, sc], class in Class, sc.class_id == class.id)
    |> join(:inner, [student, sc, class], cp in ClassPeriod, cp.id == class.class_period_id)
    |> group_by([student, sc, class, cp], cp.school_id)
    |> select([student, sc, class, cp], %{school_id: cp.school_id, count: count(student.id)})
  end

  defp get_enrolled_student_classes_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
  end
end
