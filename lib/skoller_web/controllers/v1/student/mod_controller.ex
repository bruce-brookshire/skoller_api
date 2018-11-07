defmodule SkollerWeb.Api.V1.Student.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Assignment.ModView
  alias Skoller.Mods
  alias Skoller.Mods.Students

  import SkollerWeb.Plugs.Auth
  
  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{"student_id" => student_id, "id" => id, "is_accepted" => true}) do
    case Mods.manual_accept_mod_for_student(id, student_id) do
      {:ok, student_assignment} ->
        conn
        |> render(StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"student_id" => student_id, "id" => id, "is_accepted" => false}) do
    case Mods.manual_reject_mod_for_student(id, student_id) do
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
end