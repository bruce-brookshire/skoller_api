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
            |> check_conn_for_student(conn)

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
    |> where([class, period, prof], ^filter(params))
    |> select([class, period, prof], %{class: class, professor: prof})
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

  defp check_conn_for_student(params, %{assigns: %{user: %{student: nil}}}), do: params
  defp check_conn_for_student(params, %{assigns: %{user: %{student: _}}}) do
    params |> Map.put("is_student", true)
  end
  defp check_conn_for_student(params, _conn), do: params

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

  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> school_filter(params)
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> status_filter(params)
    |> name_filter(params)
    |> number_filter(params)
    |> day_filter(params)
    |> length_filter(params)
  end

  defp school_filter(dynamic, %{"school" => filter, "or" => "true"}) do
    dynamic([class, period, prof], period.school_id == ^filter or ^dynamic)
  end
  defp school_filter(dynamic, %{"school" => filter}) do
    dynamic([class, period, prof], period.school_id == ^filter and ^dynamic)
  end
  defp school_filter(dynamic, _), do: dynamic

  defp prof_filter(dynamic, %{"professor.name" => filter, "or" => "true"}) do
    prof_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor.name" => filter}) do
    prof_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor.id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor.id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp status_filter(dynamic, %{"class.status" => "0", "or" => "true"}) do
    dynamic([class, period, prof], class.is_ghost == true or ^dynamic)
  end
  defp status_filter(dynamic, %{"class.status" => filter, "or" => "true"}) do
    dynamic([class, period, prof], (class.class_status_id == ^filter and class.is_ghost == false) or ^dynamic)
  end
  defp status_filter(dynamic, %{"class.status" => "0"}) do
    dynamic([class, period, prof], class.is_ghost == true and ^dynamic)
  end
  defp status_filter(dynamic, %{"class.status" => filter}) do
    dynamic([class, period, prof], (class.class_status_id == ^filter and class.is_ghost == false) and ^dynamic)
  end
  defp status_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class.name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class.name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp number_filter(dynamic, %{"class.number" => filter, "or" => "true"}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) or ^dynamic)
  end
  defp number_filter(dynamic, %{"class.number" => filter}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) and ^dynamic)
  end
  defp number_filter(dynamic, _), do: dynamic

  defp day_filter(dynamic, %{"class.meet_days" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.meet_days == ^filter or ^dynamic)
  end
  defp day_filter(dynamic, %{"class.meet_days" => filter}) do
    dynamic([class, period, prof], class.meet_days == ^filter and ^dynamic)
  end
  defp day_filter(dynamic, _), do: dynamic

  defp length_filter(dynamic, %{"class.length" => "1st Half", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date != class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "2nd Half", "or" => "true"}) do
    dynamic([class, period, prof], (period.end_date == class.class_end and period.start_date != class.class_start) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "Full Term", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date == class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "Custom", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date != class.class_start and period.end_date != class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "1st Half"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date != class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "2nd Half"}) do
    dynamic([class, period, prof], (period.end_date == class.class_end and period.start_date != class.class_start) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "Full Term"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date == class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class.length" => "Custom"}) do
    dynamic([class, period, prof], (period.start_date != class.class_start and period.end_date != class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, _), do: dynamic
end