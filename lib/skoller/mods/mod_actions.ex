defmodule Skoller.ModActions do
  @moduledoc """
  The context module for mod actions.
  """

  alias Skoller.Repo
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Assignment.Mod
  alias Skoller.Students

  import Ecto.Query

  @doc """
  Gets all actions from a mod.

  ## Returns
  `[Skoller.Assignment.Mod.Action]` or `[]`
  """
  def get_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> where([act], act.assignment_modification_id == ^id)
    |> Repo.all()
  end
  def get_actions_from_mod(_mod), do: []

  @doc """
  Gets all actions from a mod where the student is currently enrolled in the class.

  ## Returns
  `[Skoller.Assignment.Mod.Action]` or `[]`
  """
  def get_enrolled_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> join(:inner, [act], sc in subquery(Students.enrolled_student_class_subquery()), sc.id == act.student_class_id)
    |> where([act], act.assignment_modification_id == ^id)
    |> Repo.all()
  end
  def get_enrolled_actions_from_mod(_mod), do: []

  @doc """
  Updates an action.

  ## Returns
  `{:ok, %Skoller.Assignment.Mod.Action{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def update_action(action_old, params) do
    action_old
    |> Ecto.Changeset.change(params)
    |> Repo.update()
  end
end