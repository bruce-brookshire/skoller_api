defmodule ClassnavapiWeb.Api.V1.Student.Class.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentGradeView

  import Ecto.Query

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do

    params = params |> get_student_class(class_id, student_id)
    changeset = StudentGrade.changeset(%StudentGrade{}, params)

    case Repo.insert(changeset) do
      {:ok, student_grade} ->
        render(conn, StudentGradeView, "show.json", student_grade: student_grade)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    params = get_student_class(%{}, class_id, student_id)
    query = from(assign in Assignment)
    student_grades = query
                    |> join(:left, [assign], grade in StudentGrade, assign.id == grade.assignment_id and grade.student_class_id == ^params["student_class_id"])
                    |> where([assign, grade], assign.class_id == ^class_id)
                    |> Repo.all()
                    |> Repo.preload([:student_grades])
    render(conn, StudentGradeView, "index.json", student_grades: student_grades)
  end

  defp get_student_class(map, class_id, student_id) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    map |> Map.put("student_class_id", student_class.id)
  end
end