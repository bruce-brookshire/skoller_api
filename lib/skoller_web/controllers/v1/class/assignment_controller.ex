defmodule SkollerWeb.Api.V1.Class.AssignmentController do
  use SkollerWeb, :controller

  alias Skoller.Class.Assignment
  alias Skoller.Class.Weight
  alias Skoller.Repo
  alias SkollerWeb.AssignmentView
  alias SkollerWeb.Helpers.AssignmentHelper
  alias SkollerWeb.Helpers.RepoHelper

  import SkollerWeb.Helpers.AuthPlug
  import SkollerWeb.Helpers.LockPlug
  import Ecto.Query

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @help_req_role 500

  plug :verify_role, %{roles: [@admin_role, @change_req_role, @student_role, @syllabus_worker_role, @help_req_role]}
  plug :verify_member, :class
  plug :verify_member, %{of: :class_assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :class_id}

  def create(conn, %{"class_id" => class_id} = params) do
    params = params |> Map.put_new("weight_id", nil)
    changeset = %Assignment{}
                |> Assignment.changeset(params)
                |> check_weight_id(params)
                |> validate_class_weight(class_id)

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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    params = params |> Map.put_new("weight_id", nil)
    assign_old = Repo.get!(Assignment, id)
    changeset = assign_old
                |> Assignment.changeset(params)
                |> check_weight_id(params)
                |> validate_class_weight(assign_old.class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.update_student_assignments(&1))

    case Repo.transaction(multi) do
      {:ok, %{assignment: assignment}} ->
        render(conn, AssignmentView, "show.json", assignment: assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp check_weight_id(changeset, %{"weight_id" => nil}) do
    changeset |> Ecto.Changeset.force_change(:weight_id, nil)
  end
  defp check_weight_id(changeset, _params), do: changeset

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset, class_id) do
    weights = from(w in Weight)
    |> where([w], w.class_id == ^class_id)
    |> Repo.all

    case weights do
      [] -> changeset
      _ -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight can't be null when weights exist.")
    end
  end
  defp validate_class_weight(%Ecto.Changeset{changes: %{class_id: class_id, weight_id: weight_id}, valid?: true} = changeset, _class_id) do
    case Repo.get_by(Weight, class_id: class_id, id: weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset, _class_id), do: changeset
end