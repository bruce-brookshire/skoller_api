defmodule ClassnavapiWeb.Api.V1.Student.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Helpers.AssignmentHelper
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.ModHelper

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_member, %{of: :school, using: :class_id}
  plug :verify_member, %{of: :class, using: :id}

  def create(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    case Repo.get_by(StudentClass, student_id: student_id, class_id: class_id, is_dropped: true) do
      nil -> conn |> insert_student_class(class_id, params)
      item -> conn |> update_student_class(item)
    end
  end

  def index(conn, %{"student_id" => student_id}) do
    query = from(classes in StudentClass)
    student_classes = query
                      |> where([classes], classes.student_id == ^student_id and classes.is_dropped == false)
                      |> Repo.all()
                      |> Repo.preload(:class)
                      |> Enum.map(&Map.put(&1, :grade, ClassCalcs.get_class_grade(&1.id)))
                      |> Enum.map(&Map.put(&1, :completion, ClassCalcs.get_class_completion(&1)))
                      |> Enum.map(&Map.put(&1, :enrollment, ClassCalcs.get_enrollment(&1.class)))
                      |> Enum.map(&Map.put(&1, :status, ClassCalcs.get_class_status(&1.class)))
                      |> Enum.map(&Map.put(&1, :new_assignments, get_new_class_assignments(&1)))

    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  def show(conn, %{"student_id" => student_id, "id" => class_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    student_class = student_class |> Repo.preload(:class)

    student_class = student_class
                    |> Map.put(:grade, ClassCalcs.get_class_grade(student_class.id))
                    |> Map.put(:completion, ClassCalcs.get_class_completion(student_class))
                    |> Map.put(:enrollment, ClassCalcs.get_enrollment(student_class.class))
                    |> Map.put(:status, ClassCalcs.get_class_status(student_class.class))
                    |> Map.put(:new_assignments, get_new_class_assignments(student_class))

    render(conn, StudentClassView, "show.json", student_class: student_class)
  end

  def update(conn, %{"student_id" => student_id, "id" => class_id} = params) do
    student_class_old = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)

    changeset = StudentClass.update_changeset(student_class_old, params)

    case Repo.update(changeset) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
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
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_student_class(conn, class_id, params) do
    changeset = StudentClass.changeset(%StudentClass{}, params)

    class = Repo.get(Class, class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(&1, class))
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.insert_student_assignments(&1))

    case Repo.transaction(multi) do
      {:ok, %{student_class: student_class}} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp update_student_class(conn, item) do
    case Repo.update(Ecto.Changeset.change(item, %{is_dropped: false})) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp get_new_class_assignments(%StudentClass{} = student_class) do
    student_class |> ModHelper.get_new_assignment_mods()
  end
end