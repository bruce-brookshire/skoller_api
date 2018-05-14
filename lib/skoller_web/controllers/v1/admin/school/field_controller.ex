defmodule SkollerWeb.Api.V1.Admin.School.FieldController do
  use SkollerWeb, :controller

  alias SkollerWeb.School.FieldOfStudyView
  alias Skoller.FieldsOfStudy

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
    case FieldsOfStudy.create_field_of_study(params) do
      {:ok, field} ->
        render(conn, FieldOfStudyView, "show.json", field: field)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id}) do
    fields = FieldsOfStudy.get_field_of_study_count_by_school_id(school_id)
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def update(conn, %{"id" => id} = params) do
    field_old = FieldsOfStudy.get_field_of_study!(id)

    case FieldsOfStudy.update_field_of_study(field_old, params) do
      {:ok, field} ->
        render(conn, FieldOfStudyView, "show.json", field: field)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end