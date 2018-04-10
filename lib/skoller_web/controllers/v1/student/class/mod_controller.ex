defmodule SkollerWeb.Api.V1.Student.Class.ModController do
  use SkollerWeb, :controller

  alias Skoller.Class.StudentClass
  alias Skoller.Repo
  alias SkollerWeb.Helpers.ModHelper
  alias SkollerWeb.AssignmentView

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    assignments = student_class |> ModHelper.get_new_assignment_mods()

    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end