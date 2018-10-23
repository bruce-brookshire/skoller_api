defmodule SkollerWeb.Api.V1.Class.ChangeRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias SkollerWeb.ClassView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.ChangeRequests

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do
    params = params |> Map.put("user_id", conn.assigns[:user].id)

    case ChangeRequests.create(class_id, params) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end