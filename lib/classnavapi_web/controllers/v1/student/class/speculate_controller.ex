defmodule ClassnavapiWeb.Api.V1.Student.Class.SpeculateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentGrade
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Class.SpeculationView

  def speculate(conn, %{"grade" => grade, "class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id)
    
    student_class = student_class |> Repo.preload(:class)

    grade_speculation = student_class
                  |> Map.put(:completion, ClassCalcs.get_class_completion(student_class.id, class_id))
                  |> speculate_grade(grade)
    
    case grade_speculation do
      {:error, msg} ->
        conn
        |> render(ClassnavapiWeb.ErrorView, "error.json", error: msg)
      _ ->
        conn
        |> render(SpeculationView, "show.json", speculation: grade_speculation)
    end
  end

  defp get_class_weighted_grade(%{class_id: class_id, id: id}) do
    assignments = ClassCalcs.get_assignments_with_relative_weight(class_id)

    assignments
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, Decimal.mult(&1.relative_weight, get_assignment_grade(&1.id, id))))
  end

  defp get_assignment_grade(assign_id, student_class_id) do
    assign = Repo.get_by(StudentGrade, assignment_id: assign_id, student_class_id: student_class_id)
    case assign do
      nil -> Decimal.new(0)
      _ -> assign |> Map.get(:grade, Decimal.new(0))
    end
  end

  defp speculate_grade(%{} = student_class, grade) do
    complete = Decimal.new(1)
    case Decimal.cmp(complete, student_class.completion) do
      :eq -> {:error, "Class is already complete."}
      _ -> student_class
          |> get_grade_min(grade)
          |> Decimal.sub(get_class_weighted_grade(student_class))
          |> Decimal.div(Decimal.sub(Decimal.new(1), student_class.completion)) 
          |> Decimal.max(Decimal.new(0))
    end
  end

  defp get_grade_min(%{class: %{grade_scale: grade_scale}}, grade) do
    grade_scale
    |> String.split("|")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.find("0", &List.first(&1) == grade)
    |> List.last()
    |> Decimal.new()
  end
end