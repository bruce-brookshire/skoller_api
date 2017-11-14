defmodule ClassnavapiWeb.Api.V1.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs

  def create(conn, %{} = params) do
  
    changeset = Assignment.changeset(%Assignment{}, params)

    case Repo.insert(changeset) do
      {:ok, assignment} ->
        render(conn, AssignmentView, "show.json", assignment: assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    assignments = ClassCalcs.get_assignments_with_relative_weight(%{class_id: class_id})
    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end