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
    query = (from assign in Assignment)
    assignments = query
                  |> where([assign], assign.class_id == ^class_id)
                  |> Repo.all()
    
    assign_weights = get_relative_weight_by_id(class_id)

    assignments = assignments
    |> Enum.map(&Map.put(&1, :weight, get_weight(&1, assign_weights)))

    render(conn, AssignmentView, "index.json", assignments: assignments)
  end

  defp get_weight(%{weight_id: weight_id}, enumerable) do
    enumerable
    |> Enum.find(nil, & &1.weight_id == weight_id)
    |> Map.get(:relative)
  end

  defp get_relative_weight_by_id(class_id) do
    query = (from assign in Assignment)
    assign_count = query
                    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
                    |> where([assign], assign.class_id == ^class_id)
                    |> group_by([assign, weight], [assign.weight_id, weight.weight])
                    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id, weight: weight.weight})
                    |> Repo.all()

    weight_sum = assign_count 
                  |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))
    
    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(weight_sum)
    |> Decimal.div(Decimal.new(count))
  end
end