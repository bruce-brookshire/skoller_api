defmodule ClassnavapiWeb.Api.V1.Student.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School.StudentField
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.StudentFieldView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}

  def create(conn, %{} = params) do
    changeset = StudentField.changeset(%StudentField{}, params)

    case Repo.insert(changeset) do
      {:ok, student_field} ->
        render(conn, StudentFieldView, "show.json", student_field: student_field)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
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
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"student_id" => student_id}) do
    student_fields = Repo.all(from fs in StudentField, where: fs.student_id == ^student_id)
    render(conn, StudentFieldView, "index.json", student_fields: student_fields)
  end
end