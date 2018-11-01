defmodule SkollerWeb.Api.V1.Admin.Class.StudentRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias SkollerWeb.Class.StudentRequestView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.StudentRequests

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@change_req_role, @help_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    case StudentRequests.complete_student_request(id) do
      {:ok, %{student_request: student_request}} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end