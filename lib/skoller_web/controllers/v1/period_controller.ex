defmodule SkollerWeb.Api.V1.PeriodController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.PeriodView
  alias Skoller.Periods

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def create(conn, %{} = params) do
    case Periods.create_period(params) do
      {:ok, period} ->
        render(conn, PeriodView, "show.json", period: period)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id} = params) do
    periods = Periods.get_periods_by_school_id(school_id, params)
    render(conn, PeriodView, "index.json", periods: periods)
  end
end