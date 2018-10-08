defmodule Skoller.Assignments.Mods do
  @moduledoc """
  A context module for assignments and mods.
  """

  alias Skoller.Mods.Mod
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Repo
  alias Skoller.Assignments.Assignment

  import Ecto.Query

  @doc """
  Gets assignments with mod count and student count by class id.

  ## Returns
  `[%{assignment: %{assignment: Skoller.Assignments.Assignment, mod_count: Integer, student_count: Integer}}]` or `[]`
  """
  def get_mod_assignments_by_class(class_id) do
    from(a in Assignment)
    |> join(:left, [a], m in Mod, m.assignment_id == a.id)
    |> join(:left, [a], s in StudentAssignment, s.assignment_id == a.id)
    |> where([a], a.class_id == ^class_id)
    |> group_by([a], a.id)
    |> select([a, m, s], %{assignment: %{assignment: a, mod_count: count(m.id), student_count: count(s.id)}})
    |> Repo.all()
  end
end