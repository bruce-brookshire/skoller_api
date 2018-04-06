defmodule SkollerWeb.Api.V1.NonMemberClassController do
  use SkollerWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Skoller.Schools.Class
  alias Skoller.Repo
  alias SkollerWeb.ClassView

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role]}

  @doc """
   Shows a single `Skoller.Schools.Class`.

  ## Returns:
  * 422 `SkollerWeb.ChangesetView`
  * 404
  * 401
  * 200 `SkollerWeb.ClassView`
  """
  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, ClassView, "show.json", class: class)
  end

end