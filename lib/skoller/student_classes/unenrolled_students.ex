defmodule Skoller.UnenrolledStudents do
  @moduledoc """
  A students context for students with no enrollment.
  """

  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents

  import Ecto.Query

  def get_unenrolled_students_subquery() do
    from(s in Student)
    |> join(:left, [s], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), sc.student_id = s.id)
    |> where([s, sc], is_nil(sc.id))
  end
end