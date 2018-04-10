defmodule SkollerWeb.Api.V1.Student.ClassController do
  use SkollerWeb, :controller

  alias Skoller.Class.StudentClass
  alias Skoller.Repo
  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.Helpers.StatusHelper
  alias SkollerWeb.Helpers.ClassCalcs
  alias SkollerWeb.Helpers.AssignmentHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.ModHelper
  alias Skoller.Classes
  alias Skoller.Assignments.Mods
  alias Skoller.Students

  import Ecto.Query
  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    case Repo.get_by(StudentClass, student_id: student_id, class_id: class_id, is_dropped: true) do
      nil -> conn |> insert_student_class(class_id, params)
      item -> conn |> update_student_class(item)
    end
  end

  def show(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    student_class = student_class |> Repo.preload(:class)

    student_class = student_class
                    |> Map.put(:grade, ClassCalcs.get_class_grade(student_class.id))
                    |> Map.put(:completion, ClassCalcs.get_class_completion(student_class))
                    |> Map.put(:enrollment, Students.get_enrollment_by_class_id(class_id))
                    |> Map.put(:new_assignments, get_new_class_assignments(student_class))

    render(conn, StudentClassView, "show.json", student_class: student_class)
  end

  def update(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    student_class_old = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    changeset = StudentClass.update_changeset(student_class_old, params)

    case Repo.update(changeset) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class_old = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    changeset = StudentClass.update_changeset(student_class_old, %{"is_dropped" => true})

    case Repo.update(changeset) do
      {:ok, _student_class} ->
        conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_student_class(conn, class_id, params) do
    changeset = StudentClass.changeset(%StudentClass{}, params)

    class = Classes.get_class_by_id(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(class, &1))
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.insert_student_assignments(&1))
    |> Ecto.Multi.run(:mods, &add_public_mods(&1))
    |> Ecto.Multi.run(:auto_approve, &auto_approve_mods(&1))

    case Repo.transaction(multi) do
      {:ok, %{student_class: student_class}} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp auto_approve_mods(%{mods: mods}) do
    status = mods
    |> Enum.map(&ModHelper.process_auto_update(&1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp auto_approve_mods(_params), do: {:ok, nil}

  defp add_public_mods(%{student_class: student_class}) do
    mods = from(mod in Mod)
    |> join(:inner, [mod], class in subquery(Mods.get_class_from_mod_subquery()), mod.id == class.mod_id)
    |> where([mod], mod.is_private == false)
    |> where([mod, class], class.class_id == ^student_class.class_id)
    |> Repo.all()
    
    status = mods |> Enum.map(&insert_mod_action(student_class, &1))
    
    status |> Enum.find({:ok, mods}, &RepoHelper.errors(&1))
  end

  defp insert_mod_action(student_class, %Mod{} = mod) do
    Repo.insert(%Action{is_accepted: nil, student_class_id: student_class.id, assignment_modification_id: mod.id})
  end

  defp update_student_class(conn, item) do
    case Repo.update(Ecto.Changeset.change(item, %{is_dropped: false})) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp get_new_class_assignments(%StudentClass{} = student_class) do
    student_class |> ModHelper.get_new_assignment_mods()
  end
end