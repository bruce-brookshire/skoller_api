defmodule ClassnavapiWeb.Api.V1.Student.ModController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.ModHelper
  alias ClassnavapiWeb.Assignment.ModView
  alias Classnavapi.Class

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @student_role 100

  @new_assignment_mod 400
  @delete_assignment_mod 500
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{"student_id" => student_id, "id" => id} = params) do
    mod = Mod
    |> Repo.get!(id)
    |> Repo.preload(:assignment)

    case get_student_class(mod.assignment.class_id, student_id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_class ->
        conn |> process_mod(mod, student_class, params)
    end
  end

  def index(conn, %{"student_id" => student_id}) do
    mod_actions = from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in StudentClass, sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id not in [@new_assignment_mod, @delete_assignment_mod] and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id == @new_assignment_mod))
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
    |> Repo.all()

    conn |> render(ModView, "index.json", mods: mod_actions)
  end

  defp get_student_class(class_id, student_id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], class in Class, class.id == sc.class_id)
    |> where([sc], sc.class_id == ^class_id and sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([sc, class], class.is_editable == true)
    |> Repo.one()
  end

  defp process_mod(conn, %Mod{} = mod, %StudentClass{} = student_class, %{"is_accepted" => true}) do
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