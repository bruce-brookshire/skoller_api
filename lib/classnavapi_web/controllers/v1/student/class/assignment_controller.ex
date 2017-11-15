defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    student_assignments = ClassCalcs.get_assignments_with_relative_weight(student_class)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end
end