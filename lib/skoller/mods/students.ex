defmodule Skoller.Mods.Students do
  @moduledoc """
  A context module for mods and students
  """

  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.EnrolledStudents
  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment

  import Ecto.Query

  @due_assignment_mod 300
  @new_assignment_mod 400

  @doc """
  Gets a mod by student id and mod id.

  Student must still be enrolled in class.

  ## Returns
  `%{mod: Skoller.Mods.Mod, action: Skoller.Mods.Action, 
  student_assignment: Skoller.StudentAssignments.StudentAssignment}`, `nil`, or raises if more than one
  """
  def get_student_mod_by_id(student_id, mod_id) do
    from(mod in student_mod_base_query(student_id))
    |> where([mod], mod.id == ^mod_id)
    |> Repo.one()
  end
  
  @doc """
  Gets all the mods for a student that are due today or in the future.

  ## Params
   * `%{"is_new_assignments" => "true"}`, :boolean, returns only new assignment mods for a student
   * `%{"class_id" => class_id}`, :id, returns only mods in class with `class_id`

  ## Returns
  `[%{mod: Skoller.Mods.Mod, action: Skoller.Mods.Action, 
  student_assignment: Skoller.StudentAssignments.StudentAssignment}]` or `[]`
  """
  def get_student_mods(student_id, params \\ %{}) do
    from(mod in student_mod_base_query(student_id, params))
    |> Repo.all()
    |> Enum.filter(&filter_due_date(&1, DateTime.utc_now()))
  end

  defp student_mod_base_query(student_id, params \\ %{}) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, on: action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), on: sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, on: sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id != @new_assignment_mod and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id == @new_assignment_mod))
    |> filter(params)
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
  end

  defp filter(query, params) do
    query
    |> filter_new_assign_mods(params)
    |> filter_class(params)
  end

  defp filter_new_assign_mods(query, %{"is_new_assignments" => "true"}) do
    query
    |> where([mod], mod.assignment_mod_type_id == @new_assignment_mod)
  end
  defp filter_new_assign_mods(query, _params), do: query

  defp filter_class(query, %{"class_id" => class_id}) do
    query
    |> where([mod, action, sc], sc.class_id == ^class_id)
  end
  defp filter_class(query, _params), do: query

  defp filter_due_date(%{mod: %{assignment_mod_type_id: @due_assignment_mod} = mod}, date) do
    {:ok, mod_date, _} = DateTime.from_iso8601(mod.data["due"])
    case DateTime.compare(date, mod_date) do
      :gt -> false
      _ -> true
    end
  end
  defp filter_due_date(_mod, _date), do: true
end