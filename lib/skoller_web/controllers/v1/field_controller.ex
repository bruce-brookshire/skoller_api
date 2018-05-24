defmodule SkollerWeb.Api.V1.FieldController do
  use SkollerWeb, :controller

  alias Skoller.FieldsOfStudy
  alias SkollerWeb.School.FieldOfStudyView

  def index(conn, params) do
    fields = FieldsOfStudy.get_fields_of_study_with_filter(params)
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end
end