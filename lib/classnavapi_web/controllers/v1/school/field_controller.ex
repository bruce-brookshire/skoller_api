defmodule ClassnavapiWeb.Api.V1.School.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School.FieldOfStudy
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView

  import Ecto.Query

  def index(conn, %{"school_id" => school_id} = params) do
    query = (from fs in FieldOfStudy)
    fields = query
            |> where([fs], fs.school_id == ^school_id)
            |> filter(params)
            |> Repo.all()
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def show(conn, %{"id" => id}) do
    field = Repo.get!(FieldOfStudy, id)
    render(conn, FieldOfStudyView, "show.json", field: field)
  end

  defp filter(query, %{} = params) do
    query
    |> name_filter(params)
  end

  defp name_filter(query, %{"field_name" => filter}) do
    filter = "%" <> filter <> "%"
    query
    |> where([fs], ilike(fs.field, ^filter))
  end
  defp name_filter(query, _), do: query
end