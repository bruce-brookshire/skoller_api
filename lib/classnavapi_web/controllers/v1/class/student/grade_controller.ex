defmodule ClassnavapiWeb.Api.V1.Class.Student.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentGradeView

  import Ecto.Query

  def create(conn, %{} = params) do
  
    changeset = StudentGrade.changeset(%StudentGrade{}, params)

    case Repo.insert(changeset) do
      {:ok, grade} ->
        render(conn, StudentGradeView, "show.json", grade: grade)
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