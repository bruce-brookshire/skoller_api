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
  alias Classnavapi.School.FieldOfStudy
  alias Classnavapi.School.StudentField

  import Ecto.Query

  @doc """
  Returns the count of students in a given `Classnavapi.Schools.ClassPeriod`.

  ## Examples

      iex> val = Classnavapi.Students.get_enrollment_by_period_id(1)
      ...>Kernel.is_integer(val)
      true

  """
  def get_enrollment_by_period_id(period_id) do
    from(sc in subquery(get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> where([sc, c], c.class_period_id == ^period_id)
    |> distinct([sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the `Classnavapi.Schools.School` and a count of `Classnavapi.Student`

  ## Examples

      iex> Classnavapi.Students.get_schools_with_enrollment()
      [{school: %Classnavapi.Schools.School, students: num}]

  """
  def get_schools_with_enrollment() do
    from(school in School)
    |> join(:left, [school], student in subquery(get_school_enrollment_subquery()), student.school_id == school.id)
    |> select([school, student], %{school: school, students: fragment("coalesce(?, 0)", student.count)})
    |> Repo.all()
  end

  @doc """
  Returns the `Classnavapi.School.FieldOfStudy` and a count of `Classnavapi.Student`

  ## Examples

      iex> Classnavapi.Students.get_field_of_study_count_by_school_id()
      [{field: %Classnavapi.School.FieldOfStudy, count: num}]

  """
  def get_field_of_study_count_by_school_id(school_id) do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> where([fs], fs.school_id == ^school_id)
    |> group_by([fs, st], [fs.field, fs.id])
    |> select([fs, st], %{field: fs, count: count(st.id)})
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
