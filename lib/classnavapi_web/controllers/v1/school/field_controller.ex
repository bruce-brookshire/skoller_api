defmodule ClassnavapiWeb.Api.V1.School.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School.FieldOfStudy
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView

  import Ecto.Query

  def index(conn, %{"school_id" => school_id}) do
    query = (from fs in FieldOfStudy)
    fields = query
            |> where([fs], fs.school_id == ^school_id)
            |> Repo.all()
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def show(conn, %{"id" => id}) do
    field = Repo.get!(FieldOfStudy, id)
    render(conn, FieldOfStudyView, "show.json", field: field)
  end
end