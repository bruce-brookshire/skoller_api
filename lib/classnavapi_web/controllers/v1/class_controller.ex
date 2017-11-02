defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.SearchView

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

  def search(conn, %{"professor.name" => filter}) do
    prof_filter = "%" <> filter <> "%"
    professor_filter = from(prof in Classnavapi.Professor, where: ilike(prof.name_last, ^prof_filter))
    classes = Repo.all(from class in Class, join: period in subquery(active_period_subquery()), on: class.class_period_id == period.id,
                                            join: prof in subquery(professor_filter), on: class.professor_id == prof.id)
    conn |> render_class_search(classes)
  end

  def search(conn, _) do
    classes = Repo.all(from class in Class, join: period in subquery(active_period_subquery()), on: class.class_period_id == period.id)
    conn |> render_class_search(classes)
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

  defp render_class_search(conn, classes) do
    classes = classes |> Repo.preload([:school, :professor, :class_status])
    render(conn, SearchView, "index.json", classes: classes)
  end

  defp active_period_subquery() do
    date = Date.utc_today()
    from(period in Classnavapi.ClassPeriod, where: period.start_date <= ^date and period.end_date >= ^date)
  end
end