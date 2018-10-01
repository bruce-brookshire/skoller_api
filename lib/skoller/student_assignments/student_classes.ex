defmodule Skoller.StudentAssignments.StudentClasses do
  @moduledoc """
  A context module for enrolled student assignments
  """

  alias Skoller.EnrolledStudents
  alias Skoller.Classes.Class
  alias Skoller.ClassStatuses.Status
  alias Skoller.Repo
  alias Skoller.StudentAssignments
  alias Skoller.Mods
  alias Skoller.StudentAssignments.StudentAssignment

  import Ecto.Query

  @doc """
  Gets a student assignment with relative weight by assignment id.

  ## Returns
  `[%{Skoller.StudentClasses.StudentClass}]` with assignments or `[]`
  """
  #TODO: make this and the one argument one, one function.
  def get_student_assignment_by_id(id, :weight) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], sa in StudentAssignment, sc.id == sa.student_class_id)
    |> join(:inner, [sc, sa], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, sa, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, sa], sa.id == ^id)
    |> where([sc, sa, class, cs], cs.is_complete == true)
    |> Repo.all()
    |> Enum.flat_map(&StudentAssignments.get_assignments_with_relative_weight(&1))
    |> Enum.filter(& to_string(&1.id) == id)
    |> List.first()
  end

  @doc """
  Gets a student assignment by id in an editable class.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment` or `nil`
  """
  def get_student_assignment_by_id(id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], class in Class, sc.class_id == class.id)
    |> where([sa], sa.id == ^id)
    |> where([sa, sc, class], class.is_editable == true)
    |> Repo.one()
  end

  @doc """
  Gets student assignments with relative weights for all completed, enrolled classes of `student_id`

  ## Filters
   * %{"class", class}, filter by class.
   * %{"date", Date}, filter by due date.
   * %{"is_complete", Boolean}, filter by completion.

  ## Returns
  `[%{Skoller.StudentClasses.StudentClass}]` with assignments and is_pending_mods or `[]`
  """
  def get_student_assignments(student_id, filters) do
    from(sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, class, cs], cs.is_complete == true)
    |> where_filters(filters)
    |> Repo.all()
    |> Enum.flat_map(&StudentAssignments.get_assignments_with_relative_weight(&1))
    |> Enum.map(&Map.put(&1, :is_pending_mods, is_pending_mods(&1)))
    |> get_student_assingment_filter(filters)
  end

  defp where_filters(query, params) do
    query
    |> class_filter(params)
  end

  defp class_filter(query, %{"class" => id}) do
    query
    |> where([sc], sc.class_id == ^id)
  end
  defp class_filter(query, _params), do: query

  defp is_pending_mods(assignment) do
    case Mods.pending_mods_for_student_assignment(assignment) do
      [] -> false
      _ -> true
    end
  end

  defp get_student_assingment_filter(enumerable, params) do
    enumerable
    |> date_filter(params)
    |> completed_filter(params)
  end

  defp date_filter(enumerable, %{"date" => date}) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    enumerable
    |> Enum.filter(&not(is_nil(&1.due)) and DateTime.compare(&1.due, date) in [:gt, :eq] and &1.is_completed == false)
    |> order()
  end
  defp date_filter(enumerable, _params), do: enumerable

  defp completed_filter(enumerable, %{"is_complete" => is_complete}) do
    enumerable
    |> Enum.filter(& to_string(&1.is_completed) == is_complete)
  end
  defp completed_filter(enumerable, _params), do: enumerable

  defp order(enumerable) do
    enumerable
    |> Enum.sort(&DateTime.compare(&1.due, &2.due) in [:lt, :eq])
  end
end