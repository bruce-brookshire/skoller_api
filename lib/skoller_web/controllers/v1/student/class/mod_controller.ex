defmodule SkollerWeb.Api.V1.Student.Class.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Assignment.ModView
  alias Skoller.EnrolledStudents
  alias Skoller.Mods.Assignments

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    mods = student_class |> Assignments.get_new_assignment_mods()

    render(conn, ModView, "index.json", mods: mods)
  end
end