defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.Assignment
  alias ClassnavapiWeb.Helpers.RepoHelper

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)

    params = params |> Map.put("student_class_id", student_class.id)

    changeset = Assignment.changeset(%Assignment{}, params)
    changeset = changeset
                |> Ecto.Changeset.change(%{from_mod: true})

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{student_assignment: student_assignment}} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)
    student_assignments = ClassCalcs.get_assignments_with_relative_weight(student_class)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def update(conn, %{"id" => id} = params) do
    assign_old = Repo.get!(StudentAssignment, id)

    changeset = StudentAssignment.changeset_update(assign_old, params)

    case Repo.update(changeset) do
      {:ok, student_assignment} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    student_assignment = Repo.get!(StudentAssignment, id)
    case Repo.delete(student_assignment) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_student_assignment(%{assignment: %Assignment{} = assignment}, params) do
    params = params |> Map.put("assignment_id", assignment.id)

    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    Repo.insert(changeset)
  end
end