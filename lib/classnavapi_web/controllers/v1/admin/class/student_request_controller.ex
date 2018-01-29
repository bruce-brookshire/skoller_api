defmodule ClassnavapiWeb.Api.V1.Admin.Class.StudentRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.StudentRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequestView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.StatusHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@change_req_role, @help_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    student_request_old = Repo.get!(StudentRequest, id)

    changeset = StudentRequest.changeset(student_request_old, %{is_completed: true})

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:student_request, changeset)
    |> Ecto.Multi.run(:class_status, &StatusHelper.check_change_req_status(&1.student_request))

    case Repo.transaction(multi) do
      {:ok, %{student_request: student_request}} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end