defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.SearchView
  alias ClassnavapiWeb.Helpers.StatusHelper

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @default_grade_scale "A,90|B,80|C,70|D,60"
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role]}
  plug :verify_member, :class
  plug :verify_member, %{of: :school, using: :period_id}
  plug :verify_member, %{of: :class, using: :id}

  @doc """
   Confirms that a `Classnavapi.Class` is ready to change `Classnavapi.Class.Status` 
   from a status that will not auto progress to the next step.

  ## Returns:
  * 422 `ClassnavapiWeb.ChangesetView`
  * 404
  * 401
  * 200 `ClassnavapiWeb.ClassView`
  """
  def confirm(conn, %{"class_id" => id} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{})

    changeset = changeset
                |> StatusHelper.confirm_class(params)

    conn |> update_class(changeset)
  end

  @doc """
   Creates a new `Classnavapi.Class` for a `Classnavapi.ClassPeriod`

  ## Behavior:
   If there is no grade scale provided, a default is used: 
   A,90|B,80|C,70|D,60

  ## Returns:
  * 422 `ClassnavapiWeb.ChangesetView`
  * 401
  * 200 `ClassnavapiWeb.ClassView`
  """
  def create(conn, %{"period_id" => period_id} = params) do
    params = params
            |> grade_scale()
            |> Map.put("class_period_id", period_id)

    changeset = Class.changeset_insert(%Class{}, params)
    changeset = changeset
                |> StatusHelper.check_changeset_status(params)

    conn |> create_class(changeset)
  end

  @doc """
   Shows all `Classnavapi.Class`. Can be used as a search with multiple filters.

  ## Behavior:
   Only searches the current `Classnavapi.ClassPeriod`

  ## Filters:
  * school
    * `Classnavapi.School` :id
  * professor.name
    * `Classnavapi.Professor` :name
  * class.status
    * `Classnavapi.Class.Status` :id
    * For ghost classes, use 0.
  * class.name
    * `Classnavapi.Class` :name
  * class.number
    * `Classnavapi.Class` :number
  * class.meet_days
    * `Classnavapi.Class` :meet_days
  * class.length
    * 1st Half
    * 2nd Half
    * Full Term
    * Custom

  ## Returns:
  * 422 `ClassnavapiWeb.ChangesetView`
  * 401
  * 200 `ClassnavapiWeb.Class.SearchView`
  """
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

  @doc """
   Shows a single `Classnavapi.Class`.

  ## Returns:
  * 422 `ClassnavapiWeb.ChangesetView`
  * 404
  * 401
  * 200 `ClassnavapiWeb.ClassView`
  """
  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, ClassView, "show.json", class: class)
  end

  @doc """
   Updates a `Classnavapi.Class`.

  ## Behavior:
   If valid `Classnavapi.Class.Weight` are provided, the `Classnavapi.Class.Status` will be checked.

  ## Returns:
  * 422 `ClassnavapiWeb.ChangesetView`
  * 404
  * 401
  * 200 `ClassnavapiWeb.ClassView`
  """
  def update(conn, %{"id" => id} = params) do
    class_old = Repo.get!(Class, id)

    changeset = Class.changeset_update(class_old, params)
    
    changeset = changeset
    |> StatusHelper.check_changeset_status(params)

    conn |> update_class(changeset)
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