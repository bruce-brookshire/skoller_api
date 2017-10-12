defmodule ClassnavapiWeb.Api.V1.PeriodController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Repo
  alias ClassnavapiWeb.PeriodView

  import Ecto.Query

  def create(conn, %{} = params) do

    changeset = ClassPeriod.changeset(%ClassPeriod{}, params)

    case Repo.insert(changeset) do
      {:ok, period} ->
        render(conn, PeriodView, "show.json", period: period)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id}) do
    periods = Repo.all(from period in ClassPeriod, where: period.school_id == ^school_id)
    render(conn, PeriodView, "index.json", periods: periods)
  end

  def show(conn, %{"school_id" => school_id, "id" => id}) do
    period = Repo.get_by!(ClassPeriod, school_id: school_id, id: id)
    render(conn, PeriodView, "show.json", period: period)
  end
end