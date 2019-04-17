defmodule Skoller.StudentAssignments.Schools do
  @moduledoc """
    Context module for school student assignments
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.StudentClasses.StudentClass

  import Ecto.Query

  @doc """
  Get all student assignments in a school.

  ## Returns
  `[%Skoller.StudentAssignments.StudentAssignment{}]` or `[]`
  """
  def get_school_student_assignments(school_id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, on: sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], c in Class, on: c.id == sc.class_id)
    |> join(:inner, [sa, sc, c], s in subquery(Schools.get_school_from_class_subquery(school_id)), on: c.id == s.class_id)
    |> Repo.all()
  end
end