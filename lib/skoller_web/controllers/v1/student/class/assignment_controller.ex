defmodule SkollerWeb.Api.V1.Student.Class.AssignmentController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.StudentAssignments
  alias Skoller.Mods
  alias Skoller.AutoUpdates
  alias Skoller.ModNotifications
  alias Skoller.EnrolledStudents
  alias Skoller.StudentAssignments.StudentClasses

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student
  plug :verify_member, %{of: :student_assignment, using: :id}
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    params = params |> Map.put("student_class_id", student_class.id)

    case StudentAssignments.create_student_assignment(params) do
      {:ok, %{student_assignment: student_assignment, mod: %{mod: mod, actions: actions}}} ->
        Task.start(AutoUpdates, :process_auto_update, [mod, :notification])
        Task.start(ModNotifications, :send_mod_update_notifications, [actions])
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:ok, %{student_assignment: student_assignment}} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def index(conn, %{"student_id" => student_id} = params) do
    student_assignments = StudentClasses.get_student_assignments(student_id, params)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def show(conn, %{"id" => id}) do
    student_assignment = StudentClasses.get_student_assignment_by_id(id, :weight)
    
    pending_mods = Mods.pending_mods_for_student_assignment(student_assignment)
    student_assignment = student_assignment |> Map.put(:pending_mods, pending_mods)

    render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
  end

  def update(conn, %{"id" => id} = params) do
    case StudentClasses.get_student_assignment_by_id(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        case StudentAssignments.update_student_assignment(student_assignment, params) do
          {:ok, %{student_assignment: student_assignment, mod: %{mod: mod, actions: actions}}} ->
            student_assignment_update_success(mod, actions)
            render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
          {:ok, %{student_assignment: student_assignment, mod: mod}} ->
            mod_results = Keyword.get(mod, :ok)
            student_assignment_update_success(mod_results.mod, mod_results.actions)
            render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
          {:error, _, failed_value, _} ->
            conn
            |> MultiError.render(failed_value)
        end
    end
  end

  def delete(conn, %{"id" => id} = params) do
    case StudentClasses.get_student_assignment_by_id(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        multi = Ecto.Multi.new
        |> Ecto.Multi.delete(:student_assignment, student_assignment)
        |> Ecto.Multi.run(:mod, &Mods.insert_delete_mod(&1, params))

        case Repo.transaction(multi) do
          {:ok, %{mod: mod, actions: actions}} ->
            Task.start(AutoUpdates, :process_auto_update, [mod, :notification])
            Task.start(ModNotifications, :send_mod_update_notifications, [actions])
            conn
            |> send_resp(200, "")
          {:error, _, failed_value, _} ->
            conn
            |> MultiError.render(failed_value)
        end
    end
  end

  defp student_assignment_update_success(mod, actions) do
    Task.start(AutoUpdates, :process_auto_update, [mod, :notification])
    Task.start(ModNotifications, :send_mod_update_notifications, [actions])
  end
end