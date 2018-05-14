defmodule SkollerWeb.Api.V1.School.FieldController do
  use SkollerWeb, :controller

  alias Skoller.FieldsOfStudy
  alias SkollerWeb.School.FieldOfStudyView

  def index(conn, %{"school_id" => school_id} = params) do
    fields = FieldsOfStudy.get_fields_of_study_by_school(school_id, params)
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def show(conn, %{"id" => id}) do
    field = FieldsOfStudy.get_field_of_study!(id)
    render(conn, FieldOfStudyView, "show.json", field: field)
  end
end