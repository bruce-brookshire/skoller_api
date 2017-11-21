defmodule ClassnavapiWeb.Api.V1.Student.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.Assignment
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.ModHelper

  import Ecto.Query

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id)

    params = params |> Map.put("student_class_id", student_class.id)

    changeset = Assignment.changeset(%Assignment{}, params)
    changeset = changeset
                |> Ecto.Changeset.change(%{from_mod: true})

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:assignment, &insert_or_get_assignment(&1, changeset))
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(&1, params))
    |> Ecto.Multi.run(:mod, &ModHelper.insert_new_mod(&1, params))

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
    student_assignments = student_class
                          |> ClassCalcs.get_assignments_with_relative_weight()
                          |> ModHelper.get_pending_mods()
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def update(conn, %{"id" => id} = params) do
    assign_old = Repo.get!(StudentAssignment, id)

    changeset = StudentAssignment.changeset_update(assign_old, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, changeset)
    |> Ecto.Multi.run(:mod, &ModHelper.insert_update_mod(&1, changeset, params))

    case Repo.transaction(multi) do
      {:ok, %{student_assignment: student_assignment}} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    student_assignment = Repo.get!(StudentAssignment, id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:mod, &ModHelper.insert_delete_mod(&1, params))

    case Repo.transaction(multi) do
      {:ok, _map} ->
        conn
        |> send_resp(200, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp insert_or_get_assignment(_, %Ecto.Changeset{valid?: false} = changeset), do: {:error, changeset}
  defp insert_or_get_assignment(_, changeset) do
    assign = from(assign in Assignment)
    |> where([assign], assign.class_id == ^Ecto.Changeset.get_field(changeset, :class_id))
    |> where([assign], assign.name == ^Ecto.Changeset.get_field(changeset, :name))
    |> where([assign], ^Ecto.Changeset.get_field(changeset, :weight_id) == assign.weight_id)
    |> where([assign], ^Ecto.Changeset.get_field(changeset, :due) == assign.due)
    |> Repo.all()

    case assign do
      [] -> Repo.insert(changeset)
      assign -> {:ok, assign |> List.first}
    end
  end

  defp insert_student_assignment(%{assignment: %Assignment{} = assignment}, params) do
    params = params |> Map.put("assignment_id", assignment.id)
    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    student_assign = from(assign in StudentAssignment)
    |> where([assign], assign.student_class_id == ^params["student_class_id"])
    |> where([assign], assign.assignment_id == ^assignment.id)
    |> Repo.all()

    case student_assign do
      [] -> Repo.insert(changeset)
      student_assign -> {:error, %{student_assignment: "Assignment is already added."}}
    end
  end
end