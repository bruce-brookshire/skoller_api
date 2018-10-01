defmodule Skoller.ModActions do
  @moduledoc """
  The context module for mod actions.
  """

  alias Skoller.Repo
  alias Skoller.Mods.Action
  alias Skoller.Mods.Mod
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @doc """
  Gets all actions from a mod.

  ## Returns
  `[Skoller.Mods.Action]` or `[]`
  """
  def get_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> where([act], act.assignment_modification_id == ^id)
    |> Repo.all()
  end
  def get_actions_from_mod(_mod), do: []

  @doc """
  Inserts an unanswered mod action for `student_class`

  ## Returns
  `{:ok, Skoller.Mods.Action}` or `{:error, changeset}`
  """
  def insert_mod_action(student_class, %Mod{} = mod) do
    Repo.insert(%Action{is_accepted: nil, student_class_id: student_class.id, assignment_modification_id: mod.id})
  end

  @doc """
  Gets all actions from a mod where the student is currently enrolled in the class.

  ## Returns
  `[Skoller.Mods.Action]` or `[]`
  """
  def get_enrolled_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> join(:inner, [act], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), sc.id == act.student_class_id)
    |> where([act], act.assignment_modification_id == ^id)
    |> Repo.all()
  end
  def get_enrolled_actions_from_mod(_mod), do: []

  @doc """
  Updates an action.

  ## Returns
  `{:ok, %Skoller.Mods.Action{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def update_action(action_old, params) do
    action_old
    |> Ecto.Changeset.change(params)
    |> Repo.update()
  end

  @doc """
  Gets the pending mod count for a student.

  A pending mod is a mod that has an action for the student with `is_accepted` as `nil`

  ## Returns
  `Integer`
  """
  def get_pending_mod_count_for_student(student_id) do
    from(act in Action)
    |> join(:inner, [act], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.id == act.student_class_id)
    |> where([act], is_nil(act.is_accepted))
    |> select([act], count(act.id))
    |> Repo.one
  end

  @doc """
  Gets a mod from an action.

  ## Returns
  `%Skoller.Mods.Mod{}` or `nil`
  """
  def get_mod_from_action(%Action{} = action) do
    Repo.get(Mod, action.assignment_modification_id)
  end
end