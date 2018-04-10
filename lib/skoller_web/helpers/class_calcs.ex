defmodule SkollerWeb.Helpers.ClassCalcs do
  
  alias Skoller.Repo
  alias Skoller.Class.Assignment
  alias Skoller.Class.Weight
  alias Skoller.Class.StudentAssignment
  alias Skoller.Class.StudentClass
  alias SkollerWeb.Helpers.AssignmentHelper

  import Ecto.Query

  @moduledoc """
  
  Gets enrollment, grades, completion, etc. for controllers.

  """

  def get_class_grade(student_class_id) do
    query = from(assign in StudentAssignment)
    student_grades = query
                    |> join(:inner, [assign], weight in Weight, weight.id == assign.weight_id)
                    |> where([assign], assign.student_class_id == ^student_class_id)
                    |> group_by([assign, weight], [assign.weight_id, weight.weight])
                    |> select([assign, weight], %{grade: avg(assign.grade), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()
                    |> Enum.filter(&not(is_nil(&1.grade)))

    weight_sum = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.div(Decimal.mult(&1.weight, &1.grade), weight_sum), &2))
  end

  def get_class_completion(%StudentClass{id: student_class_id} = params) do
    relative_weights = get_relative_weight(params)

    student_class_id
    |> get_completed_assignments()
    |> Enum.reduce(Decimal.new(0), &Decimal.add(get_weight(&1, relative_weights), &2))
  end

  # Gets assignments with relative weights by either StudentAssignment or Assignments based on params.
  def get_assignments_with_relative_weight(%{} = params) do #good.
    assign_weights = get_relative_weight(params)

    params
    |> AssignmentHelper.get_assignments()
    |> Enum.map(&Map.put(&1, :relative_weight, get_weight(&1, assign_weights)))
  end

  def professor_name(class) do
    class = class |> Repo.preload(:professor)
    extract_name(class.professor, is_nil(class.professor))
  end

  defp get_relative_weight(%{class_id: class_id} = params) do #good
    assign_count_subq = params
                  |> relative_weight_subquery()

    assign_count = from(w in Weight)
    |> join(:left, [w], s in subquery(assign_count_subq), s.weight_id == w.id)
    |> where([w], w.class_id == ^class_id)
    |> select([w, s], %{weight: w.weight, count: s.count, weight_id: w.id})
    |> Repo.all()
    
    weight_sum = assign_count 
                  |> Enum.filter(& &1.weight != nil)
                  |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  defp relative_weight_subquery(%StudentClass{id: id}) do #good
    query = (from assign in StudentAssignment)
    query
    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.student_class_id == ^id)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end

  defp relative_weight_subquery(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end

  defp extract_name(_, true), do: "None"
  defp extract_name(professor, false) do
      professor.name_last
  end

  defp get_weight(%{weight_id: weight_id}, enumerable) do
    enumerable
    |> Enum.find(%{}, & &1.weight_id == weight_id)
    |> Map.get(:relative, Decimal.new(0))
  end

  defp get_completed_assignments(student_class_id) do
    query = from(assign in StudentAssignment)
    query
        |> where([assign], assign.student_class_id == ^student_class_id)
        |> where([assign], not(is_nil(assign.grade)))
        |> where([assign], not(is_nil(assign.weight_id)))
        |> Repo.all()
  end

  defp calc_relative_weight(%{count: nil}, _weight_sum), do: Decimal.new(0)
  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(Decimal.new(weight_sum))
    |> Decimal.div(Decimal.new(count))
  end

end