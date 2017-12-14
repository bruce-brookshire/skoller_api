defmodule ClassnavapiWeb.Api.V1.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.AssignmentHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.LockPlug

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300

  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class
  plug :verify_member, %{of: :class_assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :class_id}

  def create(conn, %{} = params) do
    changeset = %Assignment{}
                |> Assignment.changeset(params)
                |> validate_class_weight()

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.insert_student_assignments(&1))

    case Repo.transaction(multi) do
      {:ok, %{assignment: assignment}} ->
        render(conn, AssignmentView, "show.json", assignment: assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    assignments = AssignmentHelper.get_assignments(%{class_id: class_id})
    render(conn, AssignmentView, "index.json", assignments: assignments)
  end

  def delete(conn, %{"id" => id}) do
    class = Repo.get!(Assignment, id)

    case Repo.delete(class) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset), do: changeset
  defp validate_class_weight(%Ecto.Changeset{changes: %{class_id: class_id, weight_id: weight_id}, valid?: true} = changeset) do
    case Repo.get_by(Weight, class_id: class_id, id: weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset), do: changeset
end