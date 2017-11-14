defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView

  import Ecto.Query

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    params = get_student_class(%{}, class_id, student_id)
    query = from(assign in StudentAssignment)
    student_assignments = query
                    |> where([assign], assign.student_class_id == ^params["student_class_id"])
                    |> Repo.all()
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  defp get_student_class(map, class_id, student_id) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    map |> Map.put("student_class_id", student_class.id)
  end
end