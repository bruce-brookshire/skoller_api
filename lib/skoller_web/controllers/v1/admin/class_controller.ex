defmodule SkollerWeb.Api.V1.Admin.ClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """

  alias SkollerWeb.Admin.ClassView
  alias Skoller.Classes
  alias Skoller.Students

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role]}

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
    |> Map.put(:students, Students.get_students_by_class(id))
    render(conn, ClassView, "show.json", class: class)
  end

end