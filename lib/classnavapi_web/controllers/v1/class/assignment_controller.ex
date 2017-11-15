defmodule ClassnavapiWeb.Api.V1.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Helpers.AssignmentHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  def create(conn, %{} = params) do
  
    changeset = Assignment.changeset(%Assignment{}, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.insert_student_assignments(&1))

    case Repo.transaction(multi) do
      {:ok, %{assignment: assignment}} ->
        render(conn, AssignmentView, "show.json", assignment: assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    assignments = ClassCalcs.get_assignments_with_relative_weight(%{class_id: class_id})
    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end