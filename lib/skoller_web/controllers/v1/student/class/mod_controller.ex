defmodule SkollerWeb.Api.V1.Student.Class.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Helpers.ModHelper
  alias SkollerWeb.AssignmentView
  alias Skoller.Students

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Students.get_enrolled_class_by_ids!(class_id, student_id)

    assignments = student_class |> ModHelper.get_new_assignment_mods()

    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end