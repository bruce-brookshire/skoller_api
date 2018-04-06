defmodule ClassnavapiWeb.Api.V1.NonMemberClassController do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Classnavapi.Universities.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @change_req_role 400
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role, @change_req_role]}

  @doc """
   Shows a single `Classnavapi.Universities.Class`.

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

end