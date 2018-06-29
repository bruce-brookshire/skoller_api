defmodule SkollerWeb.Api.V1.Admin.Class.WeightController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Weights.Weight
  alias Skoller.Repo
  alias SkollerWeb.Class.WeightView
  alias Skoller.Weights

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.Lock
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role, @student_role, @syllabus_worker_role, @help_req_role]}
  plug :check_lock, %{type: :weight, using: :id}
  plug :check_lock, %{type: :weight, using: :class_id}

  def create(conn, params) do
    case Weights.insert(params) do
      {:ok, weight} ->
        render(conn, WeightView, "show.json", weight: weight)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    weight_old = Weights.get!(id)

    case Weights.update(weight_old, params) do
      {:ok, weight} ->
        render(conn, WeightView, "show.json", weight: weight)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end