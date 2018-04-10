defmodule SkollerWeb.Api.V1.Student.FieldController do
  use SkollerWeb, :controller

  alias Skoller.School.StudentField
  alias Skoller.Repo
  alias SkollerWeb.StudentView

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{} = params) do
    changeset = StudentField.changeset(%StudentField{}, params)

    case Repo.insert(changeset) do
      {:ok, student_field} ->
        student_field = student_field |> Repo.preload(:student)
        render(conn, StudentView, "show.json", student: student_field.student)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"student_id" => student_id, "id" => field_of_study_id}) do
    student_field = Repo.get_by!(StudentField, student_id: student_id, field_of_study_id: field_of_study_id)
    case Repo.delete(student_field) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end