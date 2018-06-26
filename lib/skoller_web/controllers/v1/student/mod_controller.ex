defmodule SkollerWeb.Api.V1.Student.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.ModHelper
  alias SkollerWeb.Assignment.ModView
  alias Skoller.Mods
  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  
  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{"student_id" => student_id, "id" => id} = params) do
    mod = Mod
    |> Repo.get!(id)
    |> Repo.preload(:assignment)

    case Students.get_active_student_class_by_ids(mod.assignment.class_id, student_id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_class ->
        conn |> process_mod(mod, student_class, params)
    end
  end

  def show(conn, %{"student_id" => student_id, "id" => id}) do
    mod = Mods.get_student_mod_by_id(student_id, id)
    conn |> render(ModView, "show.json", mod: mod)
  end

  def index(conn, %{"student_id" => student_id} = params) do
    mods = Mods.get_student_mods(student_id, params)
    conn |> render(ModView, "index.json", mods: mods)
  end

  defp process_mod(conn, %Mod{} = mod, %{} = student_class, %{"is_accepted" => true}) do
    case Repo.transaction(ModHelper.apply_mod(mod, student_class)) do
      {:ok, %{student_assignment: student_assignment}} ->
        Task.start(ModHelper, :process_auto_update, [mod, :notification])
        conn
        |> render(StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp process_mod(conn, %Mod{} = mod, %{} = student_class, %{"is_accepted" => false}) do
    action = Repo.get_by!(Action, assignment_modification_id: mod.id, student_class_id: student_class.id)

    case Repo.update(Ecto.Changeset.change(action, %{is_accepted: false, is_manual: true})) do
      {:ok, _} ->
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end