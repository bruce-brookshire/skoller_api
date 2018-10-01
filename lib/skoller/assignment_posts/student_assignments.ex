defmodule Skoller.AssignmentPosts.StudentAssignments do
  @moduledoc """
  A context module for student assignment posts.
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass

  import Ecto.Query

  @doc """
  Un-reads an assignment for a student.

  ## Returns
  `[{:ok, Skoller.StudentAssignments.StudentAssignment}]`
  """
  def un_read_assignment(student_id, assignment_id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> where([sa], sa.assignment_id == ^assignment_id)
    |> where([sa, sc], sc.student_id != ^student_id)
    |> Repo.all()
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: false})))
  end
end