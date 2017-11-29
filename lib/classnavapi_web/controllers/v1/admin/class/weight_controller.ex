defmodule ClassnavapiWeb.Api.V1.Admin.Class.WeightController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Weight
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.WeightView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role]}

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
end