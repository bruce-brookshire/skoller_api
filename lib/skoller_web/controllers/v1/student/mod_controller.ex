defmodule SkollerWeb.Api.V1.Student.ModController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Assignment.ModView
  alias Skoller.Mods
  alias Skoller.Mods.Students

  import SkollerWeb.Plugs.Auth, only: [verify_role: 2, verify_member: 2]
  import SkollerWeb.Plugs.InsightsAuth, only: [verify_access: 2]

  @student_role 100
  @insights_role 700

  plug :verify_role, %{roles: [@student_role, @insights_role]}
  plug :verify_member, :student
  plug :verify_access, :assignment_modification

  def create(conn, %{"student_id" => student_id, "id" => id, "is_accepted" => true}) do
    case Mods.manual_accept_mod_for_student(id, student_id) do
      {:ok, student_assignment} ->
        conn
        |> put_view(StudentAssignmentView)
        |> render("show.json", student_assignment: student_assignment)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
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
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"student_id" => student_id, "id" => id}) do
    mod = Students.get_student_mod_by_id(student_id, id)

    conn
    |> put_view(ModView)
    |> render("show.json", mod: mod)
  end

  def index(conn, %{"student_id" => student_id} = params) do
    mods = Students.get_student_mods(student_id, params)

    conn
    |> put_view(ModView)
    |> render("index.json", mods: mods)
  end
end
