defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.SearchView
  alias ClassnavapiWeb.Helpers.StatusHelper

  import Ecto.Query

  @default_grade_scale "A,90|B,80|C,70|D,60"

  def confirm(conn, %{"class_id" => id} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{})

    changeset = changeset
                |> StatusHelper.confirm_class(params)

    conn |> update_class(changeset)
  end

  def create(conn, %{"period_id" => period_id} = params) do
    params = params
            |> grade_scale()
            |> Map.put("class_period_id", period_id)

    changeset = Class.changeset_insert(%Class{}, params)
    changeset = changeset
                |> StatusHelper.check_changeset_status(params)

    conn |> create_class(changeset)
  end

  def index(conn, %{} = params) do
    date = Date.utc_today()
    query = from(class in Class)
    classes = query
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
    |> filter(params)
    |> Repo.all()

    render(conn, SearchView, "index.json", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, ClassView, "show.json", class: class)
  end

  def update(conn, %{"id" => id} = params) do
    class_old = Repo.get!(Class, id)

    params = params |> convert_points_to_weights()
    changeset = Class.changeset_update(class_old, params)
    
    changeset = changeset
    |> StatusHelper.check_changeset_status(params)

    conn |> update_class(changeset)
  end

  defp convert_points_to_weights(%{"is_points" => true} = params) do
    weights = params["weights"]
    weight_sum = weights 
                |> Enum.reduce(0, & &1["weight"] + &2)
                |> Decimal.new()
    weights = weights |> Enum.map(&Map.update!(&1, "weight", fn x -> x |> convert_weight(weight_sum) end))
    params |> Map.put("weights", weights)
  end
  defp convert_points_to_weights(params), do: params

  defp convert_weight(x, weight_sum) do
    x
    |> Decimal.new()
    |> Decimal.div(weight_sum)
    |> Decimal.mult(Decimal.new(100))
  end

  defp grade_scale(%{"grade_scale" => _} = params), do: params
  defp grade_scale(%{} = params) do
    params |> Map.put("grade_scale", @default_grade_scale)
  end

  defp create_class(conn, changeset) do
    case Repo.insert(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_class(conn, changeset) do
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
    |> length_filter(params)
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

  defp status_filter(query, %{"class.status" => "0"}) do
    query |> where([class, period, prof], class.is_ghost == true)
  end
  defp status_filter(query, %{"class.status" => filter}) do
    query |> where([class, period, prof], class.class_status_id == ^filter and class.is_ghost == false)
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

  defp length_filter(query, %{"class.length" => "1st Half"}) do
    query |> where([class, period, prof], period.start_date == class.class_start and period.end_date != class.class_end)
  end
  defp length_filter(query, %{"class.length" => "2nd Half"}) do
    query |> where([class, period, prof], period.end_date == class.class_end and period.start_date != class.class_start)
  end
  defp length_filter(query, %{"class.length" => "Full Term"}) do
    query |> where([class, period, prof], period.start_date == class.class_start and period.end_date == class.class_end)
  end
  defp length_filter(query, %{"class.length" => "Custom"}) do
    query |> where([class, period, prof], period.start_date != class.class_start and period.end_date != class.class_end)
  end
  defp length_filter(query, _), do: query
end