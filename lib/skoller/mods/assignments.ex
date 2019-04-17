defmodule Skoller.Mods.Assignments do
  @moduledoc """
  Context module for mods and assignments
  """

  alias Skoller.Mods.Mod
  alias Skoller.Repo
  alias Skoller.Mods.Action
  alias Skoller.EnrolledStudents
  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Assignments.Assignment
  
  import Ecto.Query

  @new_assignment_mod 400

  @doc """
  Gets all the mods for an assignment.

  Returns `[Skoller.Mods.Mod]` with mod action details or `[]`
  """
  def get_mods_by_assignment(assignment_id) do
    from(m in Mod)
    |> where([m], m.assignment_id == ^assignment_id)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :action, add_action_details(&1.id)))
  end

  @doc """
  Gets new assignment mods for a student that are unanswered.

  An unanswered mod is when `is_accepted` is `nil`

  ## Returns
  `[Skoller.Assignments.Assignment]` or `[]`
  """
  def get_new_assignment_mods(%StudentClass{} = student_class) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, on: mod.id == act.assignment_modification_id and act.student_class_id == ^student_class.id) 
    |> join(:inner, [mod, act], assign in Assignment, on: assign.id == mod.assignment_id)
    |> where([mod], mod.assignment_mod_type_id == ^@new_assignment_mod)
    |> where([mod, act], is_nil(act.is_accepted))
    |> Repo.all()
  end

  @doc """
  Gets other mods for the assignment.

  ## Returns
  A list of mods or `[]`
  """
  def get_other_mods_for_assignment_by_mod(mod) do
    from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.is_private == false)
    |> where([mod], mod.id != ^mod.id)
    |> Repo.all()
  end

  #This gets enrolled users' Skoller.Mods.Action and Skoller.Users.User for a given mod.
  defp add_action_details(mod_id) do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: a.student_class_id == sc.id)
    |> join(:inner, [a, sc], s in Student, on: s.id == sc.student_id)
    |> join(:inner, [a, sc, s], u in User, on: u.student_id == s.id)
    |> where([a], a.assignment_modification_id == ^mod_id)
    |> select([a, sc, s, u], %{action: a, user: u})
    |> Repo.all()
  end
end