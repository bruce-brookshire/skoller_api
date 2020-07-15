defmodule SkollerWeb.Api.V1.NonMemberClassController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.ClassView
  alias Skoller.Classes

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  @insights_role 700

  plug :verify_role, %{
    roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role, @insights_role]
  }

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

    conn
    |> put_view(ClassView)
    |> render("show.json", class: class)
  end
end
