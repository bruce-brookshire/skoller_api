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

end