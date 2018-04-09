defmodule SkollerWeb.Api.V1.ClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Skoller.Schools.Class
  alias Skoller.Repo
  alias SkollerWeb.ClassView
  alias SkollerWeb.Class.SearchView
  alias SkollerWeb.Helpers.StatusHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Classes
  alias Skoller.Students

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role]}
  plug :verify_member, :class
  plug :verify_member, %{of: :class, using: :id}
  plug :verify_class_is_editable, :class_id
  plug :verify_class_is_editable, :id

  @doc """
   Creates a new `Skoller.Schools.Class` for a `Skoller.Schools.ClassPeriod`

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def create(conn, %{"period_id" => period_id} = params) do
    params = params
    |> Map.put("class_period_id", period_id)

    case Classes.create_class(params, conn.assigns[:user]) do
      {:ok, %{class_status: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  @doc """
   Shows all `Skoller.Schools.Class`. Can be used as a search with multiple filters.

   ## Filters:
  * school
    * `Skoller.Schools.School` :id
  * professor.name
    * `Skoller.Professor` :name
  * class.status
    * `Skoller.Class.Status` :id
    * For ghost classes, use 0.
  * class.name
    * `Skoller.Schools.Class` :name
  * class.number
    * `Skoller.Schools.Class` :number
  * class.meet_days
    * `Skoller.Schools.Class` :meet_days
  * class.length
    * 1st Half
    * 2nd Half
    * Full Term
    * Custom

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 401
  * 200 `SkollerWeb.Class.SearchView`
  """
  def index(conn, params) do
    classes = Students.get_classes_with_enrollment(params)

    render(conn, SearchView, "index.json", classes: classes)
  end

  @doc """
   Updates a `Skoller.Schools.Class`.

  ## Behavior:
   If valid `Skoller.Class.Weight` are provided, the `Skoller.Class.Status` will be checked.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def update(conn, %{"id" => id} = params) do
    class_old = Repo.get!(Class, id)

    changeset = Class.university_changeset(class_old, params)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_status, &StatusHelper.check_status(&1.class, nil))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end