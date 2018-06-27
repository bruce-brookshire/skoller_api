defmodule SkollerWeb.Api.V1.Student.Class.AssignmentController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.ModHelper
  alias SkollerWeb.Helpers.NotificationHelper
  alias Skoller.Students
  alias Skoller.StudentAssignments

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student
  plug :verify_member, %{of: :student_assignment, using: :id}
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Students.get_enrolled_class_by_ids!(class_id, student_id)

    params = params |> Map.put("student_class_id", student_class.id)

    case StudentAssignments.create_student_assignment(params) do
      {:ok, %{student_assignment: student_assignment, mod: mod}} ->
        Task.start(ModHelper, :process_auto_update, [mod, :notification])
        Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, %{"student_id" => student_id} = params) do
    student_assignments = Students.get_student_assignments(student_id, params)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def show(conn, %{"id" => id}) do
    student_assignment = Students.get_student_assignment_by_id(id, :weight)
    
    pending_mods = ModHelper.pending_mods_for_assignment(student_assignment)
    student_assignment = student_assignment |> Map.put(:pending_mods, pending_mods)

    render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
  end

  def update(conn, %{"id" => id} = params) do
    case Students.get_student_assignment_by_id(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        case StudentAssignments.update_student_assignment(student_assignment, params) do
          {:ok, %{student_assignment: student_assignment, mod: mod}} ->
            Task.start(ModHelper, :process_auto_update, [mod, :notification])
            Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
            render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
          {:error, _, failed_value, _} ->
            conn
            |> RepoHelper.multi_error(failed_value)
        end
    end
  end

  def delete(conn, %{"id" => id} = params) do
    case Students.get_student_assignment_by_id(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        multi = Ecto.Multi.new
        |> Ecto.Multi.delete(:student_assignment, student_assignment)
        |> Ecto.Multi.run(:mod, &ModHelper.insert_delete_mod(&1, params))

        case Repo.transaction(multi) do
          {:ok, %{mod: mod}} ->
            Task.start(ModHelper, :process_auto_update, [mod, :notification])
            Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
            conn
            |> send_resp(200, "")
          {:error, _, failed_value, _} ->
            conn
            |> RepoHelper.multi_error(failed_value)
        end
    end
  end
end