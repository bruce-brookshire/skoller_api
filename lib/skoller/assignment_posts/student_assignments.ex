defmodule Skoller.AssignmentPosts.StudentAssignments do
  @moduledoc """
  A context module for student assignment posts.
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.MapErrors

  import Ecto.Query

  @doc """
  Un-reads an assignment for a student.

  ## Returns
  `{:ok, [{:ok, Skoller.StudentAssignments.StudentAssignment}]}`
  """
  def un_read_assignment(student_id, assignment_id) do
    status = from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, on: sc.id == sa.student_class_id)
    |> where([sa], sa.assignment_id == ^assignment_id)
    |> where([sa, sc], sc.student_id != ^student_id)
    |> Repo.all()
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: false})))

    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
end