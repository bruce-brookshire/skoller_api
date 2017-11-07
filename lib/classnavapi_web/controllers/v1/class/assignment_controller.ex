defmodule ClassnavapiWeb.Api.V1.Class.AssignmentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AssignmentView

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

    subquery = (from assign in Assignment)
    assign_count = subquery
                    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
                    |> where([assign], assign.class_id == ^class_id)
                    |> group_by([assign, weight], [assign.weight_id, weight.weight])
                    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()

    query = (from assign in Assignment)
    assignments = query
                  #|> join(:inner, [assign], ac in subquery(assign_count), ac.weight_id == assign.weight_id)
                  |> where([assign], assign.class_id == ^class_id)
                  #|> select([assign, ac], %{assignment: assign, weight: ac})
                  |> Repo.all()
    require IEx
    IEx.pry
    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end