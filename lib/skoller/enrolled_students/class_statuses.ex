defmodule Skoller.EnrolledStudents.ClassStatuses do
  @moduledoc """
  A context module for enrolled students in class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Classes.Class
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @needs_syllabus_status 200

  @doc """
  Gets a list of students that have classes that need setup.
  """
  def get_students_needs_setup_classes() do
    from(s in Student)
    |> join(:inner, [s], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), sc.student_id == s.id)
    |> join(:inner, [s, sc], c in Class, sc.class_id == c.id)
    |> where([s, sc, c], c.class_status_id == @needs_syllabus_status)
    |> preload([s], [:users])
    |> distinct([s], s.id)
    |> Repo.all()
  end
end