defmodule SkollerWeb.Api.V1.FieldController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.FieldsOfStudy
  alias SkollerWeb.School.FieldOfStudyView

  def index(conn, %{"field_name" => search_term} = params) do
    fields = FieldsOfStudy.get_fields_of_study_with_filter(params)

    if Enum.count(fields) < 10 && String.contains?(search_term, " ") do
      fields =
        (fields ++
           (search_term
            |> String.split(" ")
            |> Enum.filter(&(&1 != ""))
            |> Enum.flat_map(
              &FieldsOfStudy.get_fields_of_study_with_filter(%{"field_name" => &1})
            )))
        |> Enum.uniq_by(& &1.id)

      render(conn, FieldOfStudyView, "index.json", fields: fields)
    else
      render(conn, FieldOfStudyView, "index.json", fields: fields)
    end
  end

  def index(conn, params) do
    fields = FieldsOfStudy.get_fields_of_study_with_filter(params)
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end
end
