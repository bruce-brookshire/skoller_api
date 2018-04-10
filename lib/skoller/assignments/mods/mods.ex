defmodule Skoller.Assignments.Mods do

  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Class.StudentClass
  alias Skoller.Class.StudentAssignment
  alias Skoller.Repo
  alias Skoller.Class.Assignment

  import Ecto.Query

  @due_assignment_mod 300
  @new_assignment_mod 400

  def get_student_mods(student_id) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in StudentClass, sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id not in [@new_assignment_mod] and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id in [@new_assignment_mod]))
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
    |> Repo.all()
    |> Enum.filter(&filter_due_date(&1, DateTime.utc_now()))
  end

  def get_class_from_mod_subquery() do
    from(mod in Mod)
    |> join(:inner, [mod], assign in Assignment, mod.assignment_id == assign.id)
    |> select([mod, assign], %{class_id: assign.class_id, mod_id: mod.id})
  end

  defp filter_due_date(%{mod: %{assignment_mod_type_id: @due_assignment_mod} = mod}, date) do
    {:ok, mod_date, _} = DateTime.from_iso8601(mod.data["due"])
    case DateTime.compare(date, mod_date) do
      :gt -> false
      _ -> true
    end
  end
  defp filter_due_date(_mod, _date), do: true
end