defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias Classnavapi.Class.StudentAssignment

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    student_assignments = ClassCalcs.get_assignments_with_relative_weight(student_class)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def delete(conn, %{"id" => id}) do
    assignment = Repo.get!(StudentAssignment, id)
    case Repo.delete(assignment) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end