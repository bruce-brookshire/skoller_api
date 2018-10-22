defmodule Skoller.EnrolledStudents.ClassStatuses do
  @moduledoc """
  A context module for enrolled students in class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents
  alias Skoller.ClassStatuses.Classes

  import Ecto.Query

  @doc """
  Gets a list of students that have classes that need setup.
  """
  def get_students_needs_setup_classes() do
    from(s in Student)
    |> join(:inner, [s], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), sc.student_id == s.id)
    |> join(:inner, [s, sc], c in subquery(Classes.needs_setup_classes_subquery()), sc.class_id == c.id)
    |> preload([s], [:users])
    |> distinct([s], s.id)
    |> Repo.all()
  end
end