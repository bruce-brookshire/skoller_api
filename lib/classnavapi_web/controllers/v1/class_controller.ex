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
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Professor
  alias Classnavapi.School
  alias Classnavapi.Class.Status
  alias Classnavapi.Class.StudentClass

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
  plug :verify_class_is_editable, :class_id
  plug :verify_class_is_editable, :id

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
    date = DateTime.utc_now
    query = from(class in Class)
    classes = query
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Professor, class.professor_id == prof.id)
    |> join(:inner, [class, period, prof], school in School, school.id == period.school_id)
    |> join(:inner, [class, period, prof, school], status in Status, status.id == class.class_status_id)
    |> join(:left, [class, period, prof, school, status], enroll in subquery(count_subquery()), enroll.class_id == class.id)
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
    |> where([class, period, prof], ^filter(params))
    |> select([class, period, prof, school, status, enroll], %{class: class, class_period: period, professor: prof, school: school, class_status: status, enroll: enroll})
    |> Repo.all()

    render(conn, SearchView, "index.json", classes: classes)
  end

  def count_subquery() do
    from(c in Class)
    |> join(:left, [c], sc in StudentClass, c.id == sc.class_id)
    |> where([c, sc], sc.is_dropped == false)
    |> group_by([c, sc], c.id)
    |> select([c, sc], %{class_id: c.id, count: count(sc.id)})
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
    |> ghost_filter(params)
    |> maint_filter(params)
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

  defp prof_filter(dynamic, %{"professor_name" => filter, "or" => "true"}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor_name" => filter}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], (ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter)) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor_id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor_id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp status_filter(dynamic, %{"class_status" => "0", "or" => "true"}) do
    dynamic([class, period, prof], class.is_ghost == true or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.class_status_id == ^filter or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => "0"}) do
    dynamic([class, period, prof], class.is_ghost == true and ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter}) do
    dynamic([class, period, prof], class.class_status_id == ^filter and ^dynamic)
  end
  defp status_filter(dynamic, _), do: dynamic

  defp ghost_filter(dynamic, %{"class_status" => "0"}), do: dynamic
  defp ghost_filter(dynamic, %{"ghost" => "true"}) do
    dynamic([class, period, prof], class.is_ghost == true and ^dynamic)
  end
  defp ghost_filter(dynamic, %{"ghost" => "false"}) do
    dynamic([class, period, prof], class.is_ghost == false and ^dynamic)
  end
  defp ghost_filter(dynamic, _), do: dynamic

  defp maint_filter(dynamic, %{"class_maint" => "true"}) do
    dynamic([class, period, prof], class.is_editable == false and ^dynamic)
  end
  defp maint_filter(dynamic, %{"class_maint" => "false"}) do
    dynamic([class, period, prof], class.is_editable == true and ^dynamic)
  end
  defp maint_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class_name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class_name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp number_filter(dynamic, %{"class_number" => filter, "or" => "true"}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) or ^dynamic)
  end
  defp number_filter(dynamic, %{"class_number" => filter}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) and ^dynamic)
  end
  defp number_filter(dynamic, _), do: dynamic

  defp day_filter(dynamic, %{"class_meet_days" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.meet_days == ^filter or ^dynamic)
  end
  defp day_filter(dynamic, %{"class_meet_days" => filter}) do
    dynamic([class, period, prof], class.meet_days == ^filter and ^dynamic)
  end
  defp day_filter(dynamic, _), do: dynamic

  defp length_filter(dynamic, %{"class_length" => "1st Half", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date != class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "2nd Half", "or" => "true"}) do
    dynamic([class, period, prof], (period.end_date == class.class_end and period.start_date != class.class_start) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "Full Term", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date == class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "Custom", "or" => "true"}) do
    dynamic([class, period, prof], (period.start_date != class.class_start and period.end_date != class.class_end) or ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "1st Half"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date != class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "2nd Half"}) do
    dynamic([class, period, prof], (period.end_date == class.class_end and period.start_date != class.class_start) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "Full Term"}) do
    dynamic([class, period, prof], (period.start_date == class.class_start and period.end_date == class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, %{"class_length" => "Custom"}) do
    dynamic([class, period, prof], (period.start_date != class.class_start and period.end_date != class.class_end) and ^dynamic)
  end
  defp length_filter(dynamic, _), do: dynamic
end