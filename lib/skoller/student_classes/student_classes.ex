defmodule Skoller.StudentClasses do
  @moduledoc """
  Context module for students in classes.
  """

  alias Skoller.Repo
  alias Skoller.Class.Weight
  alias Skoller.StudentAssignments.StudentAssignment

  import Ecto.Query

  @doc """
  Gets a grade for a student class.

  ## Returns
  `Decimal`
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
end