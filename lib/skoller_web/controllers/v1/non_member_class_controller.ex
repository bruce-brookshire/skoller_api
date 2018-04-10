defmodule SkollerWeb.Api.V1.NonMemberClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """

  alias SkollerWeb.ClassView
  alias Skoller.Classes

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role]}

  @doc """
   Shows a single class.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def show(conn, %{"id" => id}) do
    class = Classes.get_class_by_id!(id)
    render(conn, ClassView, "show.json", class: class)
  end

end