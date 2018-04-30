defmodule SkollerWeb.Api.V1.Student.ClassController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.Helpers.ClassCalcs
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.ModHelper
  alias Skoller.Students

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    case Students.get_enrolled_class_by_ids(class_id, student_id) do
      nil -> conn |> insert_student_class(class_id, params)
      item -> conn |> update_student_class(item)
    end
  end

  def link(conn, %{"token" => token} = params) do
    case Students.enroll_by_link(token, conn.assigns[:user].student.id, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end


  def show(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = Students.get_enrolled_class_by_ids!(class_id, student_id)

    student_class = student_class
                    |> Map.put(:grade, ClassCalcs.get_class_grade(student_class.id))
                    |> Map.put(:completion, ClassCalcs.get_class_completion(student_class))
                    |> Map.put(:enrollment, Students.get_enrollment_by_class_id(class_id))
                    |> Map.put(:new_assignments, get_new_class_assignments(student_class))

    render(conn, StudentClassView, "show.json", student_class: student_class)
  end

  def update(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    old = Students.get_enrolled_class_by_ids!(class_id, student_id)

    case Students.update_enrolled_class(old, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = Students.get_enrolled_class_by_ids!(class_id, student_id)

    case Students.drop_enrolled_class(student_class) do
      {:ok, _student_class} ->
        conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_student_class(conn, class_id, params) do
    case Students.enroll_in_class(class_id, params) do
      {:ok, student_class} ->
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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp get_new_class_assignments(%{} = student_class) do
    student_class |> ModHelper.get_new_assignment_mods()
  end
end