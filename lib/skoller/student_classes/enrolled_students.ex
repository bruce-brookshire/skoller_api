defmodule Skoller.EnrolledStudents do
  @moduledoc """
  A context module based on enrolled students
  """

  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Repo

  import Ecto.Query

  @enrollment_limit 15

  @doc """
  Subquery that gets enrolled students in a class

  Returns subquery with `Skoller.StudentClasses.StudentClass`.
  """
  def enrolled_student_class_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
  end

  @doc """
  Subquery for getting enrolled student classes by student.
  """
  def get_enrolled_classes_by_student_id_subquery(student_id) do
    #TODO: Filter ClassPeriod
    from(sc in StudentClass)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
  end

  @doc """
  Returns `Skoller.StudentClasses.StudentClass` with `Skoller.Classes.Class` that a `Skoller.Students.Student` currently has.

  ## Examples

      iex> val = Skoller.EnrolledStudents.get_enrolled_classes_by_student_id(1)
      [%Skoller.StudentClasses.StudentClass{class: %Skoller.Classes.Class{}}]

  """
  def get_enrolled_classes_by_student_id(student_id) do
    #TODO: Filter ClassPeriod
    from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.all()
    |> Repo.preload(:class)
  end

  def check_enrollment_limit_for_student(student_id) do
    class_count = from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.aggregate(:count, :id)

    class_count < @enrollment_limit
  end
end