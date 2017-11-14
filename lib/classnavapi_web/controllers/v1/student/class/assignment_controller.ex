defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs

  import Ecto.Query

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    assignments = ClassCalcs.get_assignments_with_relative_weight(student_class)
    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end