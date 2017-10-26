defmodule ClassnavapiWeb.Api.V1.Class.WeightController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Weight
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.WeightView
  
    import Ecto.Query
  
    def update(conn, %{"id" => id} = params) do
    
      weight_old = Repo.get!(Weight, id)
      changeset = Weight.changeset(weight_old, params)
  
      case Repo.update(changeset) do
        {:ok, weight} ->
          render(conn, WeightView, "show.json", weight: weight)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end
  
    def index(conn, %{"class_id" => class_id}) do
      weights = Repo.all(from a in Weight, where: a.class_id == ^class_id)
      render(conn, WeightView, "index.json", weights: weights)
    end
  end