defmodule SkollerWeb.Api.V1.Admin.PeriodController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.PeriodView
  alias Skoller.Periods

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def show(conn, %{"id" => id}) do
    period = Periods.get_period!(id)

    conn
    |> put_view(PeriodView)
    |> render("show.json", period: period)
  end

  def update(conn, %{"id" => id} = params) do
    period_old = Periods.get_period!(id)

    case Periods.update_period(period_old, params) do
      {:ok, period} ->
        conn
        |> put_view(PeriodView)
        |> render("show.json", period: period)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
