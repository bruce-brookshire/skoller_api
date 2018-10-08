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
  
  import Ecto.Query

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

  #This gets enrolled users' Skoller.Mods.Action and Skoller.Users.User for a given mod.
  defp add_action_details(mod_id) do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), a.student_class_id == sc.id)
    |> join(:inner, [a, sc], s in Student, s.id == sc.student_id)
    |> join(:inner, [a, sc, s], u in User, u.student_id == s.id)
    |> where([a], a.assignment_modification_id == ^mod_id)
    |> select([a, sc, s, u], %{action: a, user: u})
    |> Repo.all()
  end
end