defmodule ClassnavapiWeb.Api.V1.Admin.Class.StudentRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.StudentRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequestView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@change_req_role, @help_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    student_request_old = Repo.get!(StudentRequest, id)

    changeset = StudentRequest.changeset(student_request_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, student_request} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end