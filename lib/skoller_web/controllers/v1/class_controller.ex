defmodule SkollerWeb.Api.V1.ClassController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.ClassView
  alias SkollerWeb.Class.SearchView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Classes
  alias Skoller.StudentClasses.Classes, as: EnrolledClasses
  alias Skoller.Periods

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @insights_role 700

  plug :verify_role, %{
    roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role, @insights_role]
  }

  plug :verify_member, :class
  plug :verify_member, %{of: :class, using: :id}
  plug :verify_class_is_editable, :class_id
  plug :verify_class_is_editable, :id

  def dashboard_classes(conn, params) do
    classes = EnrolledClasses.get_classes_with_enrollment(params)

    conn
    |> put_view(SearchView)
    |> render("index.json", classes: classes)
  end

  def dashboard_classes_count(conn, _params) do
    json(conn, EnrolledClasses.classes_count |> List.first)
  end

  @doc """
   Creates a new class through `Skoller.Classes`

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def create(conn, %{"period_id" => period_id} = params) do
    params =
      params
      |> Map.put("class_period_id", period_id)

    case Classes.create_class(params, conn.assigns[:user]) do
      {:ok, %{class_status: class}} ->
        conn
        |> put_view(ClassView)
        |> render("show.json", class: class)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  @doc """
   Returns all classes for the period and filters

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def index(conn, %{"period_id" => period_id} = params) do
    classes = Periods.get_classes_by_period_id(period_id, params)

    conn
    |> put_view(ClassView)
    |> render("index.json", classes: classes)
  end


  #  Shows all classes. Can be used as a search with multiple filters.

  #  ## Filters:
  # * school
  #   * school id
  # * professor_name
  #   * professor name
  # * class_status
  #   * class status id
  #   * For ghost classes, use 0.
  # * class_name
  # * class_number
  # * class_meet_days

  # ## Returns:
  # * 422 `SkollerWeb.ChangesetView`
  # * 401
  # * 200 `SkollerWeb.Class.SearchView`
  def index(conn, params) do
    classes = EnrolledClasses.get_classes_with_enrollment(params)

    conn
    |> put_view(SearchView)
    |> render("index.json", classes: classes)
  end

  @doc """
   Updates a class through `Skoller.Classes`.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def update(%{assigns: %{user: user}} = conn, %{"id" => id} = params) do
    class_old = Classes.get_class_by_id!(id)

    case Classes.update_class(class_old, params, user.id) do
      {:ok, %{class: class}} ->
        conn
        |> put_view(ClassView)
        |> render("show.json", class: class)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end
