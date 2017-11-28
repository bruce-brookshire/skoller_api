defmodule ClassnavapiWeb.Api.V1.Admin.ProfessorController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Professor
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ProfessorView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role]}

  def update(conn, %{"id" => id} = params) do
    professor_old = Repo.get!(Professor, id)
    changeset = Professor.changeset_update(professor_old, params)

    case Repo.update(changeset) do
      {:ok, professor} ->
        render(conn, ProfessorView, "show.json", professor: professor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end