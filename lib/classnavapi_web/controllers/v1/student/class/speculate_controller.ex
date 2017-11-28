defmodule ClassnavapiWeb.Api.V1.Student.Class.SpeculateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Class.SpeculationView

  def speculate(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id)
    
    student_class = student_class |> Repo.preload(:class)

    grade_speculation = student_class
                  |> Map.put(:completion, ClassCalcs.get_class_completion(student_class))
                  |> speculate_grade(params)
    
    case grade_speculation do
      {:error, msg} ->
        conn
        |> render(ClassnavapiWeb.ErrorView, "error.json", error: msg)
      %{} ->
        conn
        |> render(SpeculationView, "show.json", speculation: %{grade: params["grade"], speculation: grade_speculation})
      _ -> 
        conn
        |> render(SpeculationView, "index.json", speculations: grade_speculation)
    end
  end

  defp get_class_weighted_grade(%StudentClass{} = params) do
    assignments = ClassCalcs.get_assignments_with_relative_weight(params)

    assignments
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, Decimal.mult(&1.relative_weight, get_assignment_grade(&1))))
  end

  defp get_assignment_grade(%StudentAssignment{id: id}) do
    assign = Repo.get!(StudentAssignment, id)
    grade = assign
    |> Map.get(:grade)

    case grade do
      nil -> Decimal.new(0)
      _ -> grade
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
    grade_scale
    |> String.split("|")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.find("0", &List.first(&1) == grade)
    |> List.last()
    |> Decimal.new()
  end

  defp get_grade_min(%{class: %{grade_scale: grade_scale}}) do
    grade_scale
    |> String.split("|")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.map(&Map.new(grade: List.first(&1), min: Decimal.new(List.last(&1))))
  end
end