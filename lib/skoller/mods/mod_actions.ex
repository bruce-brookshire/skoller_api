defmodule Skoller.ModActions do
  @moduledoc """
  The context module for mod actions.
  """

  alias Skoller.Repo
  alias Skoller.Mods.Action
  alias Skoller.Mods.Mod
  alias Skoller.EnrolledStudents
  alias Skoller.Students
  alias Skoller.Assignments.Assignment

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

  @doc """
  Gets public mods that have at least one response as well as the accepted and response count.

  ## Returns
  `[%{mod: Skoller.Mods.Mod, responses: Integer, accepted: Integer}]` or `[]`
  """
  def get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted = true and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id)) #Get mods with a response that is not from the creator.
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, accepted: act.accepted})
    |> Repo.all()
  end

  @doc """
  Gets public mods audience and response count.

  ## Returns
  `[%{mod: Skoller.Mods.Mod, responses: Integer, audience: Integer}]` or `[]`
  """
  def get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, audience: act.audience})
    |> Repo.all()
  end

  @doc """
  Gets public mods that have not been auto updated, but have enough students to be auto updated.
  
  ## Returns
  `[%{assignment_modification_id: Id, responses: Integer, audience: Integer, accepted: Integer}]` or `[]`
  """
  def get_non_auto_update_mods_in_enrollment_threshold(enrollment_threshold) do
    from(m in Mod)
    |> join(:inner, [m], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> where([m], m.is_auto_update == false and m.is_private == false)
    |> where([m, act, a], fragment("exists (select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false group by class_id having count(1) > ?)", a.class_id, ^enrollment_threshold))
    |> select([m, act], act)
    |> Repo.all()
  end

  #This is a subquery that returns the responses for a mod of all enrolled students in that class.
  defp mod_responses_sub() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> group_by([a], a.assignment_modification_id)
    |> select([a], %{assignment_modification_id: a.assignment_modification_id, responses: count(a.is_accepted), audience: count(a.id), accepted: sum(fragment("?::int", a.is_accepted))})
  end
end