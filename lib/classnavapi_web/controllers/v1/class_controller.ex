defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.SearchView

  import Ecto.Query

  def complete(conn, %{"class_id" => id, "is_diy" => false}) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{"class_status_id" => 300})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def complete(conn, %{"class_id" => id}) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{"class_status_id" => 500})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"grade_scale" => _, "period_id" => period_id} = params) do
    params = params |> Map.put("class_period_id", period_id)

    changeset = Class.changeset_insert(%Class{}, params)

    case Repo.insert(changeset) do
      {:ok, class} ->
        class = class |> Repo.preload(:class_period)
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"period_id" => period_id} = params) do
    params = params |> Map.put("grade_scale", "A,90|B,80|C,70|D,60")
    params = params |> Map.put("class_period_id", period_id)

    changeset = Class.changeset_insert(%Class{}, params)

    case Repo.insert(changeset) do
      {:ok, class} ->
        class = class |> Repo.preload(:class_period)
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{} = params) do
    date = Date.utc_today()
    query = from(class in Class)
    query
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
    |> filter(params)
    |> Repo.all()
    |> render_class_search(conn)
  end

  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    class = class |> Repo.preload(:class_period)
    render(conn, ClassView, "show.json", class: class)
  end

  def update(conn, %{"id" => id, "weights" => _} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, params)
    
    changeset = changeset
    |> Ecto.Changeset.change(%{class_status_id: 200})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
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
    |> school_filter(params)
    |> prof_filter(params)
    |> status_filter(params)
    |> name_filter(params)
    |> number_filter(params)
    |> day_filter(params)
  end

  defp school_filter(query, %{"school" => filter}) do
    query |> where([class, period, prof], period.school_id == ^filter)
  end
  defp school_filter(query, _), do: query

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

  defp number_filter(query, %{"class.number" => filter}) do
    number_filter = "%" <> filter <> "%"
    query |> where([class, period, prof], ilike(class.number, ^number_filter))
  end
  defp number_filter(query, _), do: query

  defp day_filter(query, %{"class.meet_days" => filter}) do
    query |> where([class, period, prof], class.meet_days == ^filter)
  end
  defp day_filter(query, _), do: query

  defp render_class_search(classes, conn) do
    classes = classes |> Repo.preload([:school, :professor, :class_status, :students])
    render(conn, SearchView, "index.json", classes: classes)
  end
end