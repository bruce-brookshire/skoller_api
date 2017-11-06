defmodule ClassnavapiWeb.Api.V1.Class.StudentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView

  import Ecto.Query

  def create(conn, %{} = params) do

    changeset = StudentClass.changeset(%StudentClass{}, params)

    case Repo.insert(changeset) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    student_class = Repo.get!(StudentClass, id)
    query = from(grades in StudentGrade)
    student_grades = query
                    |> join(:inner, [grades], assign in Assignment, grades.assignment_id == assign.id)
                    |> join(:inner, [grades, assign], weight in Weight, weight.id == assign.weight_id)
                    |> where([grades], grades.student_class_id == ^student_class.id)
                    |> group_by([grades, assign, weight], [assign.weight_id, weight.weight])
                    |> select([grades, assign, weight], %{grade: avg(grades.grade), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()

    weight_sum = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    grade = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.div(Decimal.mult(&1.weight, &1.grade), weight_sum), &2))

    student_class = student_class |> Map.put(:grade, grade)
    render(conn, StudentClassView, "show.json", student_class: student_class)
  end
end