defmodule ClassnavapiWeb.Api.V1.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs

  import Ecto.Query

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
    query = (from assign in Assignment)
    assignments = query
                  |> where([assign], assign.class_id == ^class_id)
                  |> Repo.all()
    
    assign_weights = ClassCalcs.get_relative_weight_by_class_id(class_id)

    assignments = assignments
    |> Enum.map(&Map.put(&1, :weight, get_weight(&1, assign_weights)))

    render(conn, AssignmentView, "index.json", assignments: assignments)
  end

  defp get_weight(%{weight_id: weight_id}, enumerable) do
    enumerable
    |> Enum.find(nil, & &1.weight_id == weight_id)
    |> Map.get(:relative)
  end
end