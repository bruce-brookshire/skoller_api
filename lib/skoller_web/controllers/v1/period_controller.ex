defmodule SkollerWeb.Api.V1.PeriodController do
  @moduledoc false
  use SkollerWeb, :controller

  alias SkollerWeb.PeriodView
  alias Skoller.Periods

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def create(%{assigns: %{user: user}} = conn, %{} = params) do
    is_admin = user.roles |> Enum.any?(&(&1.id == @admin_role))

    case Periods.create_period(params, admin: is_admin) do
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

  def index(conn, %{"school_id" => school_id} = params) do
    periods = Periods.get_periods_by_school_id(school_id, params)

    conn
    |> put_view(PeriodView)
    |> render("index.json", periods: periods)
  end
end
