defmodule Skoller.StudentClasses do
  @moduledoc """
  Context module for students in classes.
  """

  alias Skoller.Repo
  alias Skoller.Weights.Weight
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools

  import Ecto.Query

  @doc """
  Gets a grade for a student class.

  ## Returns
  `Decimal`
  """
  def get_class_grade(student_class_id) do
    query = from(assign in StudentAssignment)
    student_grades = query
                    |> join(:inner, [assign], weight in Weight, weight.id == assign.weight_id)
                    |> where([assign], assign.student_class_id == ^student_class_id)
                    |> group_by([assign, weight], [assign.weight_id, weight.weight])
                    |> select([assign, weight], %{grade: avg(assign.grade), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()
                    |> Enum.filter(&not(is_nil(&1.grade)))

    weight_sum = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.div(Decimal.mult(&1.weight, &1.grade), weight_sum), &2))
  end

  @doc """
  This gets a student class by the class and student id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_student_class_by_student_and_class(class_id, student_id) do
    Repo.get_by(StudentClass, class_id: class_id, student_id: student_id)
  end

  @doc """
  This gets a student class by the student class id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_student_class_by_id(id) do
    Repo.get(StudentClass, id)
  end

  @doc """
  This gets a student class by the student class id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `Ecto.NoResultsError`
  """
  def get_student_class_by_id!(id) do
    Repo.get!(StudentClass, id)
  end

  @doc """
  Gets most common school from a list of student classes.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `Ecto.NoResultsError`
  """
  def get_most_common_school([]), do: nil
  def get_most_common_school(student_classes) do
    max = student_classes
    |> Enum.map(&Schools.get_school_from_period(&1.class.class_period_id))
    |> Enum.chunk_by(& &1.id)
    |> Enum.map(& %{school: List.first(&1), count: Enum.count(&1)})
    |> Enum.max_by(& &1.count)
    max.school
  end

  @doc """
  Gets student classes in a class. Includes previously-enrolled students.

  ## Returns
  `[Skoller.StudentClasses.StudentClass]` or `[]`
  """
  def get_studentclasses_by_class(class_id) do
    from(sc in StudentClass)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.all()
  end
end