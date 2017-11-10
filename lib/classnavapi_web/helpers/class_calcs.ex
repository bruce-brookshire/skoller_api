defmodule ClassnavapiWeb.Helpers.ClassCalcs do
  
  alias Classnavapi.Repo
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.StudentGrade

  import Ecto.Query

  @moduledoc """
  
  Gets enrollment, grades, completion, etc. for controllers.

  """

  def get_class_grade(student_class_id) do
    query = from(grades in StudentGrade)
    student_grades = query
                    |> join(:inner, [grades], assign in Assignment, grades.assignment_id == assign.id)
                    |> join(:inner, [grades, assign], weight in Weight, weight.id == assign.weight_id)
                    |> where([grades], grades.student_class_id == ^student_class_id)
                    |> group_by([grades, assign, weight], [assign.weight_id, weight.weight])
                    |> select([grades, assign, weight], %{grade: avg(grades.grade), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()

    weight_sum = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.div(Decimal.mult(&1.weight, &1.grade), weight_sum), &2))
  end

  def get_class_completion(student_class_id, class_id) do
    relative_weights = get_relative_weight_by_class_id(class_id)

    student_class_id
    |> get_completed_assignments()
    |> Repo.preload(:assignment)
    |> Enum.reduce(Decimal.new(0), &Decimal.add(get_relative_weight_by_weight(&1.assignment.weight_id, relative_weights), &2))
  end

  def get_relative_weight_by_class_id(class_id) do
    query = (from assign in Assignment)
    assign_count = query
                    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
                    |> where([assign], assign.class_id == ^class_id)
                    |> group_by([assign, weight], [assign.weight_id, weight.weight])
                    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()

    weight_sum = assign_count 
                  |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))
    
    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  defp get_relative_weight_by_weight(weight_id, relative_weights) do
    relative_weights
    |> Enum.find(0, & &1.weight_id == weight_id)
    |> Map.get(:relative, 0)
  end

  defp get_completed_assignments(student_class_id) do
    query = from(grades in StudentGrade)
    query
        |> join(:inner, [grades], assign in Assignment, grades.assignment_id == assign.id)
        |> where([grades], grades.student_class_id == ^student_class_id)
        |> Repo.all()
  end

  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(weight_sum)
    |> Decimal.div(Decimal.new(count))
  end

end