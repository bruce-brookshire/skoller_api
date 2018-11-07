defmodule SkollerWeb.Api.V1.Student.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Mods.Mod
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Assignment.ModView
  alias Skoller.Mods
  alias Skoller.Mods.Students
  alias Skoller.AutoUpdates
  alias Skoller.StudentClasses

  import SkollerWeb.Plugs.Auth
  
  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{"student_id" => student_id, "id" => id} = params) do
    mod = Mod
    |> Repo.get!(id)
    |> Repo.preload(:assignment)

    case StudentClasses.get_active_student_class_by_ids!(mod.assignment.class_id, student_id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_class ->
        conn |> process_mod(mod, student_class, params)
    end
  end

  def create(conn, %{"student_id" => student_id, "id" => id} = %{"is_accepted" => false}) do
    case Mods.reject_mod_for_student(id, student_id) do
      {:ok, _} ->
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"student_id" => student_id, "id" => id}) do
    mod = Students.get_student_mod_by_id(student_id, id)
    conn |> render(ModView, "show.json", mod: mod)
  end

  def index(conn, %{"student_id" => student_id} = params) do
    mods = Students.get_student_mods(student_id, params)
    conn |> render(ModView, "index.json", mods: mods)
  end

  defp process_mod(conn, %Mod{} = mod, %{} = student_class, %{"is_accepted" => true}) do
    case Repo.transaction(Mods.apply_mod(mod, student_class)) do
      {:ok, %{student_assignment: student_assignment}} ->
        Task.start(AutoUpdates, :process_auto_update, [mod, [notification: true]])
        conn
        |> render(StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end