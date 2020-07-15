defmodule SkollerWeb.Api.V1.Admin.Class.WeightController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.WeightView
  alias Skoller.Weights

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.Lock

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @help_req_role 500
  @insights_role 700

  plug :verify_role, %{
    roles: [@admin_role, @change_req_role, @student_role, @syllabus_worker_role, @help_req_role, @insights_role]
  }

  plug :check_lock, %{type: :weight, using: :id}
  plug :check_lock, %{type: :weight, using: :class_id}

  def create(%{assigns: %{user: user}} = conn, params) do
    case Weights.insert_weight(user.id, params) do
      {:ok, weight} ->
        conn
        |> put_view(WeightView)
        |> render("show.json", weight: weight)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(%{assigns: %{user: user}} = conn, %{"id" => id} = params) do
    weight_old = Weights.get_weight!(id)

    case Weights.update_weight(user.id, weight_old, params) do
      {:ok, weight} ->
        conn
        |> put_view(WeightView)
        |> render("show.json", weight: weight)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    weight = Weights.get_weight!(id)

    case Weights.delete_weight(weight) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
