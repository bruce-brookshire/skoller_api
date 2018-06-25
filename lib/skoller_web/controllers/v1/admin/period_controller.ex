defmodule SkollerWeb.Api.V1.Admin.PeriodController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Schools.ClassPeriod
  alias Skoller.Repo
  alias SkollerWeb.PeriodView
  
  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def show(conn, %{"id" => id}) do
    period = Repo.get!(ClassPeriod, id)
    render(conn, PeriodView, "show.json", period: period)
  end

  def update(conn, %{"id" => id} = params) do
    period_old = Repo.get!(ClassPeriod, id)
    changeset = ClassPeriod.changeset_update(period_old, params)

    case Repo.update(changeset) do
      {:ok, period} ->
        render(conn, PeriodView, "show.json", period: period)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end