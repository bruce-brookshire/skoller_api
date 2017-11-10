defmodule ClassnavapiWeb.Api.V1.Student.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.StudentGrade
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.Helpers.StatusHelper

  import Ecto.Query

  def create(conn, %{"class_id" => class_id} = params) do

    changeset = StudentClass.changeset(%StudentClass{}, params)

    class = Repo.get(Class, class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(&1, class))

    case Repo.transaction(multi) do
      {:ok, %{student_class: student_class}} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
        {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: failed_value)
    end
  end

  def index(conn, %{"student_id" => student_id}) do
    query = from(classes in StudentClass)
    student_classes = query
                      |> where([classes], classes.student_id == ^student_id)
                      |> Repo.all()
    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  def show(conn, %{"student_id" => student_id, "id" => class_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id)
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