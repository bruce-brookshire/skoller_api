defmodule ClassnavapiWeb.Api.V1.School.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School.FieldOfStudy
  alias Classnavapi.School.StudentField
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :school

  def index(conn, %{"school_id" => school_id}) do
    query = (from fs in FieldOfStudy)
    fields = query
            |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
            |> where([fs], fs.school_id == ^school_id)
            |> group_by([fs, st], [fs.field, fs.id])
            |> select([fs, st], %{field: fs, count: count(st.id)})
            |> Repo.all()
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def show(conn, %{"id" => id}) do
    field = Repo.get!(FieldOfStudy, id)
    render(conn, FieldOfStudyView, "show.json", field: field)
  end
end