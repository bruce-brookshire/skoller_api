defmodule SkollerWeb.Api.V1.Admin.Class.ChangeRequestMemberController do
  use SkollerWeb, :controller

  alias Skoller.Class.ChangeRequestView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.ChangeRequests.ChangeRequestMembers

  import SkollerWeb.Plugs.Auth

  @admin_role 200
  @change_req_role 400

  plug :verify_role, %{roles: [@change_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    case ChangeRequestMembers.set_completed(id) do
      {:ok, %{change_request_member_update: member}} ->
        render(conn, ChangeRequestView, "show.json", change_request_member: member)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end
