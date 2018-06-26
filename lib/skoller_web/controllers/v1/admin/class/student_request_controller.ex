defmodule SkollerWeb.Api.V1.Admin.Class.StudentRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Class.StudentRequest
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentRequestView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Classes

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@change_req_role, @help_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    student_request_old = Repo.get!(StudentRequest, id)

    changeset = StudentRequest.changeset(student_request_old, %{is_completed: true})

    class = Classes.get_class_by_id(student_request_old.class_id)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:student_request, changeset)
    |> Ecto.Multi.run(:class_status, &Classes.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{student_request: student_request}} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end