defmodule ClassnavapiWeb.Api.V1.Student.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias ClassnavapiWeb.Helpers.ClassCalcs

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
                      |> Enum.map(&Map.put(&1, :grade, ClassCalcs.get_class_grade(&1.id)))
                      |> Enum.map(&Map.put(&1, :completion, ClassCalcs.get_class_completion(&1.id, &1.class_id)))

    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  def show(conn, %{"student_id" => student_id, "id" => class_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id)

    grade = ClassCalcs.get_class_grade(student_class.id)

    student_class = student_class |> Map.put(:grade, grade)
    render(conn, StudentClassView, "show.json", student_class: student_class)
  end
end