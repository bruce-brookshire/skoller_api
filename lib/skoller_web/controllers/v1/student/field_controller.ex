defmodule SkollerWeb.Api.V1.Student.FieldController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Students
  alias SkollerWeb.StudentView

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def create(conn, %{} = params) do
    case Students.add_field_of_study(params) do
      {:ok, student_field} ->
        render(conn, StudentView, "show.json", student: student_field.student)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"student_id" => student_id, "id" => field_of_study_id}) do
    student_field = Students.get_field_of_study_by_id!(student_id, field_of_study_id)
    case Students.delete_field_of_study(student_field) do
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