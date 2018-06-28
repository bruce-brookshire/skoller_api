defmodule SkollerWeb.Helpers.ModHelper do
  use SkollerWeb, :controller

  @moduledoc """
  
  Helper for inserting mods.

  """

  alias Skoller.Class.Assignment
  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentAssignments.StudentAssignment

  import Ecto.Query

  @new_assignment_mod 400

  def pending_mods_for_assignment(%StudentAssignment{} = student_assignment) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([m], m.assignment_id == ^student_assignment.assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end

  def pending_mods_for_assignment(%{student_class_id: student_class_id, assignment_id: assignment_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_class_id)
    |> where([m], m.assignment_id == ^assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end

  def get_new_assignment_mods(%StudentClass{} = student_class) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id and act.student_class_id == ^student_class.id) 
    |> join(:inner, [mod, act], assign in Assignment, assign.id == mod.assignment_id)
    |> where([mod], mod.assignment_mod_type_id == ^@new_assignment_mod)
    |> where([mod, act], is_nil(act.is_accepted))
    |> select([mod, act, assign], assign)
    |> Repo.all()
  end
end