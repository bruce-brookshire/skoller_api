defmodule SkollerWeb.Api.V1.Student.Class.SpeculateController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.SpeculationView
  alias Skoller.EnrolledStudents
  alias Skoller.EnrolledStudents.Grades

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student

  def speculate(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)
    
    case Grades.speculate_grade(student_class, params) do
      {:error, msg} ->
        conn
        |> render(SkollerWeb.ErrorView, "error.json", error: msg)
      grade_speculation when is_map(grade_speculation) ->
        conn
        |> render(SpeculationView, "show.json", speculation: %{grade: params["grade"], speculation: grade_speculation})
      grade_speculation -> 
        conn
        |> render(SpeculationView, "index.json", speculations: grade_speculation)
    end
  end
end