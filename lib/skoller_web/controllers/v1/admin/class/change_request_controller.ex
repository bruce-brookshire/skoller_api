defmodule SkollerWeb.Api.V1.Admin.Class.ChangeRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.ChangeRequests
  alias SkollerWeb.Class.ChangeRequestView
  alias SkollerWeb.Responses.MultiError

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@change_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    case ChangeRequests.complete(id) do
      {:ok, %{change_request: change_request}} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end