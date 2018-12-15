defmodule Skoller.Analytics.Grades do
  @moduledoc """
  A context module for running analytics on grades
  """

  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.EnrolledStudents
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets a count of all assignments with grades from enrolled students.
  
  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_grades_entered_count(params) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), sc.id == sa.student_class_id)
    |> where([sa], not is_nil(sa.grade))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of all student classes with at least 1 grade from enrolled students.
  
  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_student_classes_with_grades_count(params) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), sc.id == sa.student_class_id)
    |> where([sa], not is_nil(sa.grade))
    |> distinct([sa], [sa.student_class_id])
    |> Repo.aggregate(:count, :id)
  end
end