defmodule SkollerWeb.Api.V1.ClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias SkollerWeb.ClassView
  alias SkollerWeb.Class.SearchView
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
   Creates a new class through `Skoller.Classes`

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
   Shows all classes through `Skoller.Students`. Can be used as a search with multiple filters.

   ## Filters:
  * school
    * school id
  * professor_name
    * professor name
  * class_status
    * class status id
    * For ghost classes, use 0.
  * class_name
  * class_number
  * class_meet_days

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
   Updates a class through `Skoller.Classes`.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def update(conn, %{"id" => id} = params) do
    class_old = Classes.get_class_by_id!(id)

    case Classes.update_class(class_old, params) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end