defmodule ClassnavapiWeb.Api.V1.Student.ModController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.ModHelper
  alias ClassnavapiWeb.Assignment.ModView

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{"student_id" => student_id, "id" => id} = params) do
    mod = Mod
    |> Repo.get!(id)
    |> Repo.preload(:assignment)

    student_class = Repo.get_by!(StudentClass, class_id: mod.assignment.class_id, student_id: student_id, is_dropped: false)

    conn |> process_mod(mod, student_class, params)
  end

  def index(conn, %{"student_id" => student_id}) do
    mod_actions = from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in StudentClass, sc.id == action.student_class_id)
    |> where([mod, action, sc], sc.student_id == ^student_id)
    |> select([mod, action, sc], %{mod: mod, action: action})
    |> Repo.all()

    conn |> render(ModView, "index.json", mods: mod_actions)
  end

  defp process_mod(conn, %Mod{} = mod, %StudentClass{} = student_class, %{"is_accepted" => true}) do
    case Repo.transaction(ModHelper.apply_mod(mod, student_class)) do
      {:ok, %{student_assignment: student_assignment}} ->
        conn
        |> render(StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp process_mod(conn, %Mod{} = mod, %StudentClass{} = student_class, %{"is_accepted" => false}) do
    action = Repo.get_by!(Action, assignment_modification_id: mod.id, student_class_id: student_class.id)

    case Repo.update(Ecto.Changeset.change(action, %{is_accepted: false})) do
      {:ok, _} ->
        conn
        |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end