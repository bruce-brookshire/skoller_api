defmodule SkollerWeb.Api.V1.Class.AssignmentController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.AssignmentView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Assignments
  alias Skoller.Assignments.Classes

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.Lock

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @help_req_role 500

  plug :verify_role, %{
    roles: [@admin_role, @change_req_role, @student_role, @syllabus_worker_role, @help_req_role]
  }

  plug :verify_member, :class
  plug :verify_member, %{of: :class_assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :id}
  plug :check_lock, %{type: :assignment, using: :class_id}

  def create(%{assigns: %{user: user}} = conn, %{"class_id" => class_id} = params) do
    case Assignments.create_assignment(class_id, user.id, params) do
      {:ok, %{assignment: assignment}} ->
        conn
        |> put_view(AssignmentView)
        |> render("show.json", assignment: assignment)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    assignments = Classes.get_assignments_by_class(class_id)

    conn
    |> put_view(AssignmentView)
    |> render("index.json", assignments: assignments)
  end

  def delete(conn, %{"id" => id}) do
    case Assignments.delete_assignment(id) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(%{assigns: %{user: user}} = conn, %{"id" => id} = params) do
    case Assignments.update_assignment(id, user.id, params) do
      {:ok, %{assignment: assignment}} ->
        conn
        |> put_view(AssignmentView)
        |> render("show.json", assignment: assignment)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end
