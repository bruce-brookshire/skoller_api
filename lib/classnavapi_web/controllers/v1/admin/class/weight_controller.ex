defmodule ClassnavapiWeb.Api.V1.Admin.Class.WeightController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Weight
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.WeightView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role]}

  def create(conn, params) do
    changeset = Weight.changeset_admin(%Weight{}, params)

    case Repo.insert(changeset) do
      {:ok, weight} ->
        render(conn, WeightView, "show.json", weight: weight)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

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

  def delete(conn, %{"id" => id}) do
    weight = Repo.get!(Weight, id)

    case Repo.delete(weight) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end