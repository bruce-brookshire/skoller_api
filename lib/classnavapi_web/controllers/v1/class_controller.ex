defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView

  import Ecto.Query

  def create(conn, %{} = params) do

    changeset = Class.changeset_insert(%Class{}, params)

    case Repo.insert(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def search(conn, _) do
    date = Date.utc_today()
    active_periods = from(period in Classnavapi.ClassPeriod, where: period.start_date <= ^date and period.end_date >= ^date)
    classes = Repo.all(from class in Class, join: period in subquery(active_periods), on: class.class_period_id == period.id)
    render(conn, ClassView, "index.json", classes: classes)
  end

  def index(conn, _) do
    classes = Repo.all(Class)
    render(conn, ClassView, "index.json", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, ClassView, "show.json", class: class)
  end

  def update(conn, %{"id" => id} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, params)

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end