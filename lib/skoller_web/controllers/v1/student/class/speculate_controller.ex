defmodule SkollerWeb.Api.V1.Student.Class.SpeculateController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias SkollerWeb.Class.SpeculationView
  alias Skoller.Students
  alias Skoller.StudentAssignments

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student

  def speculate(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Students.get_enrolled_class_by_ids!(class_id, student_id)
    
    student_class = student_class |> Repo.preload(:class)

    grade_speculation = student_class
                  |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
                  |> speculate_grade(params)
    
    case grade_speculation do
      {:error, msg} ->
        conn
        |> render(SkollerWeb.ErrorView, "error.json", error: msg)
      %{} ->
        conn
        |> render(SpeculationView, "show.json", speculation: %{grade: params["grade"], speculation: grade_speculation})
      _ -> 
        conn
        |> render(SpeculationView, "index.json", speculations: grade_speculation)
    end
  end

  defp get_class_weighted_grade(%{} = params) do
    assignments = StudentAssignments.get_assignments_with_relative_weight(params)

    assignments
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, Decimal.mult(&1.relative_weight, get_assignment_grade(&1))))
  end

  defp get_assignment_grade(%StudentAssignment{} = assign) do
    case assign |> Map.get(:grade) do
      nil -> Decimal.new(0)
      grade -> grade
    end
  end

  defp speculate_grade(%{} = student_class, %{"grade" => grade}) do
    complete = Decimal.new(1)
    case Decimal.cmp(complete, Decimal.round(student_class.completion, 5)) do
      :eq -> {:error, "Class is already complete."}
      _ -> student_class
          |> get_grade_min(grade)
          |> calculate_speculation(student_class)
    end
  end
  defp speculate_grade(%{} = student_class, _params) do
    complete = Decimal.new(1)
    case Decimal.cmp(complete, Decimal.round(student_class.completion, 5)) do
      :eq -> {:error, "Class is already complete."}
      _ -> student_class
          |> get_grade_min()
          |> Enum.map(&Map.put(&1, :speculation, calculate_speculation(&1.min, student_class)))
    end
  end

  defp calculate_speculation(grade, student_class) do
    grade
    |> Decimal.sub(get_class_weighted_grade(student_class))
    |> Decimal.div(Decimal.sub(Decimal.new(1), student_class.completion))
    |> Decimal.max(Decimal.new(0))
  end

  defp get_grade_min(%{class: %{grade_scale: grade_scale}}, grade) do
    grade = grade_scale
    |> Enum.map(&Map.new(grade: Kernel.elem(&1, 0), min: Decimal.new(Kernel.elem(&1, 1))))
    |> Enum.find(& &1.grade == grade)
    grade.min
  end

  defp get_grade_min(%{class: %{grade_scale: grade_scale}}) do
    grade_scale
    |> Enum.map(&Map.new(grade: Kernel.elem(&1, 0), min: Decimal.new(Kernel.elem(&1, 1))))
  end
end