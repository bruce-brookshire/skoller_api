defmodule SkollerWeb.Api.V1.Class.StudentRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.StudentRequests
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Class.StudentRequestView

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{} = params) do
    params = params |> Map.put("user_id", user.id)
    case StudentRequests.create(user, params["class_id"], params) do
      {:ok, %{student_request: student_request}} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end