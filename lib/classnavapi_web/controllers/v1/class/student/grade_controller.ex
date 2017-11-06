defmodule ClassnavapiWeb.Api.V1.Class.Student.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Class.StudentClass
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
    student_grades = from(grade in StudentGrade)
    |> where([grade], grade.student_class_id == ^params["student_class_id"])
    |> Repo.all()
    render(conn, StudentGradeView, "index.json", student_grades: student_grades)
  end

  defp get_student_class(map, class_id, student_id) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    map |> Map.put("student_class_id", student_class.id)
  end
end