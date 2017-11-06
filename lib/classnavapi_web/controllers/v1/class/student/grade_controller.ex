defmodule ClassnavapiWeb.Api.V1.Class.Student.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentGradeView

  import Ecto.Query

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
  
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    params = params
    |> Map.put("student_class_id", student_class.id)
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
    grades = Repo.all(from a in StudentGrade, where: a.class_id == ^class_id and a.student_id == ^student_id)
    render(conn, StudentGradeView, "index.json", grades: grades)
  end
end