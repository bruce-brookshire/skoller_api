defmodule Skoller.Mods.StudentAssignments do
  @moduledoc """
  A context module for mods and student assignments
  """

  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets unanswered mods for a student assignment.

  An unanswered mod is when `is_accepted` is `nil`

  ## Returns
  `[Skoller.Mods.Mod]` or `[]`
  """
  def pending_mods_for_student_assignment(%{student_class_id: student_class_id, assignment_id: assignment_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, on: m.id == act.assignment_modification_id and act.student_class_id == ^student_class_id)
    |> where([m], m.assignment_id == ^assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end
end