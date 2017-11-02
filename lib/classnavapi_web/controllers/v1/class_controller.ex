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

  def search(conn, %{} = params) do
    date = Date.utc_today()
    from(class in Class)
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
    |> filter(params)
    |> Repo.all()
    |> render_class_search(conn)
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

  defp filter(query, %{} = params) do
    query
    |> prof_filter(params)
    |> status_filter(params)
    |> name_filter(params)
  end

  defp prof_filter(query, %{"professor.name" => filter}) do
    prof_filter = "%" <> filter <> "%"
    query |> where([class, period, prof], ilike(prof.name_last, ^prof_filter))
  end
  defp prof_filter(query, _), do: query

  defp status_filter(query, %{"class.status" => filter}) do
    query |> where([class, period, prof], class.class_status_id == ^filter)
  end
  defp status_filter(query, _), do: query

  defp name_filter(query, %{"class.name" => filter}) do
    name_filter = "%" <> filter <> "%"
    query |> where([class, period, prof], ilike(class.name, ^name_filter))
  end
  defp name_filter(query, _), do: query

  defp render_class_search(classes, conn) do
    classes = classes |> Repo.preload([:school, :professor, :class_status])
    render(conn, SearchView, "index.json", classes: classes)
  end
end