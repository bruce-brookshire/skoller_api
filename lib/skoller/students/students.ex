defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.Class.StudentClass
  alias Skoller.Schools.Class
  alias Skoller.Schools.School
  alias Skoller.Student
  alias Skoller.School.FieldOfStudy
  alias Skoller.School.StudentField
  alias Skoller.Classes

  import Ecto.Query

  @doc """
  Returns `Skoller.Class.StudentClass` with `Skoller.Schools.Class` that a `Skoller.Student` currently has.

  ## Examples

      iex> val = Skoller.Students.get_enrolled_classes_by_student_id(1)
      [%Skoller.Class.StudentClass{class: %Skoller.Schools.Class{}}]

  """
  def get_enrolled_classes_by_student_id(student_id) do
    #TODO: Filter ClassPeriod
    from(classes in StudentClass)
    |> where([classes], classes.student_id == ^student_id and classes.is_dropped == false)
    |> Repo.all()
    |> Repo.preload(:class)
  end

  @doc """
  Returns the count of students in a given `Skoller.Schools.ClassPeriod`.

  ## Examples

      iex> val = Skoller.Students.get_enrollment_by_period_id(1)
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
  Returns the `Skoller.Schools.School` and a count of `Skoller.Student`

  ## Examples

      iex> Skoller.Students.get_schools_with_enrollment()
      [{school: %Skoller.Schools.School, students: num}]

  """
  def get_schools_with_enrollment() do
    from(school in School)
    |> join(:left, [school], student in subquery(get_school_enrollment_subquery()), student.school_id == school.id)
    |> select([school, student], %{school: school, students: fragment("coalesce(?, 0)", student.count)})
    |> Repo.all()
  end

  @doc """
  Returns the `Skoller.School.FieldOfStudy` and a count of `Skoller.Student`

  ## Examples

      iex> Skoller.Students.get_field_of_study_count_by_school_id()
      [{field: %Skoller.School.FieldOfStudy, count: num}]

  """
  def get_field_of_study_count_by_school_id(school_id) do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> where([fs], fs.school_id == ^school_id)
    |> group_by([fs, st], [fs.field, fs.id])
    |> select([fs, st], %{field: fs, count: count(st.id)})
    |> Repo.all()
  end

  @doc """
  Returns a subquery that provides a unique list of `Skoller.Schools.School` ids and `Skoller.Student` ids

  """
  def get_schools_for_student_subquery() do
    from(student in Student)
    |> join(:inner, [student], sc in subquery(get_enrolled_student_classes_subquery()), sc.student_id == student.id)
    |> join(:inner, [student, sc], class in subquery(Classes.get_school_from_class_subquery()), sc.class_id == class.class_id)
    |> distinct([student, sc, class], [student.id, class.school_id])
    |> select([student, sc, class], %{student_id: student.id, school_id: class.school_id})
  end

  def get_student_subquery(_params \\ %{})
  @doc """
  Returns a subquery that provides a list of `Skoller.Student` by `Skoller.Schools.School`

  """
  def get_student_subquery(%{"school_id" => _school_id} = params) do
    from(s in Student)
    |> join(:inner, [s], sc in StudentClass, sc.student_id == s.id)
    |> join(:inner, [s, sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([s, sc], sc.is_dropped == false)
    |> distinct([s], s.id)
  end
  @doc """
  Returns a subquery that provides a list of `Skoller.Student`

  """
  def get_student_subquery(_params) do
    from(s in Student)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.Class.StudentClass` where the classes are not dropped by `Skoller.Schools.School`

  """
  def get_enrolled_student_classes_subquery(params \\ %{}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([sc], sc.is_dropped == false)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.Schools.Class`

  """
  def get_enrolled_classes_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> distinct([sc], sc.class_id)
  end

  defp get_school_enrollment_subquery() do
    from(s in subquery(get_schools_for_student_subquery()))
    |> group_by([s], s.school_id)
    |> select([s], %{school_id: s.school_id, count: count(s.student_id)})
  end
end
