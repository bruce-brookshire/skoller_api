defmodule Skoller.EnrolledStudents.Grades do
  @moduledoc """
  A context module for student class grades
  """

  alias Skoller.StudentAssignments
  alias Skoller.Repo

  def speculate_grade(student_class, params) do
    results = student_class
    |> Repo.preload(:class)
    |> check_class_grade_scale()
    |> check_class_completion()

    case results do
      {:ok, student_class} ->
        student_class
        |> get_grade_min(params)
        |> speculate_class_grade(student_class)
      {:error, result} ->
        {:error, result}
    end
  end

  defp check_class_grade_scale(%{class: %{grade_scale: nil}}) do
    {:error, "No grade scale for class"}
  end
  defp check_class_grade_scale(student_class), do: {:ok, student_class}

  defp check_class_completion({:ok, student_class}) do
    complete = Decimal.new(1)
    student_class = student_class |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
    case Decimal.cmp(complete, Decimal.round(student_class.completion, 5)) do
      :eq -> {:error, "Class is already complete."}
      _ -> {:ok, student_class}
    end
  end
  defp check_class_completion({:error, resp}), do: {:error, resp}

  defp get_class_weighted_grade(%{} = params) do
    assignments = StudentAssignments.get_assignments_with_relative_weight(params)

    assignments
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, Decimal.mult(&1.relative_weight, get_assignment_grade(&1))))
  end

  defp get_grade_min(%{class: %{grade_scale: grade_scale}}, %{"grade" => grade}) do
    grade = grade_scale
    |> grade_scale_min_map()
    |> Enum.find(& &1.grade == grade)
    grade.min
  end
  defp get_grade_min(%{class: %{grade_scale: grade_scale}}, _params) do
    grade_scale |> grade_scale_min_map()
  end

  # Returns a list of %{grade: grade, min: min}
  defp grade_scale_min_map(grade_scale) do
    grade_scale
    |> Enum.map(&Map.new(grade: Kernel.elem(&1, 0), min: Decimal.new(Kernel.elem(&1, 1))))
  end

  defp get_assignment_grade(assign) do
    case assign |> Map.get(:grade) do
      nil -> Decimal.new(0)
      grade -> grade
    end
  end

  defp speculate_class_grade(grade, student_class) when is_list(grade) do
    grade
    |> Enum.map(&Map.put(&1, :speculation, calculate_speculation(&1.min, student_class)))
  end
  defp speculate_class_grade(grade, student_class) do
    grade
    |> calculate_speculation(student_class)
  end

  defp calculate_speculation(grade, student_class) do
    grade
    |> Decimal.sub(get_class_weighted_grade(student_class))
    |> Decimal.div(Decimal.sub(Decimal.new(1), student_class.completion))
    |> Decimal.max(Decimal.new(0))
  end
end