defmodule Skoller.UnenrolledStudents do
  @moduledoc """
  A students context for students with no enrollment.
  """

  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents
  alias Skoller.Repo

  import Ecto.Query

  def get_unenrolled_students() do
    from(s in Student)
    |> join(:left, [s], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), on: sc.student_id == s.id)
    |> where([s, sc], is_nil(sc.id))
    |> preload([s], [:users])
    |> Repo.all()
  end
end
