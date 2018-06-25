defmodule SkollerWeb.Api.V1.SammiController do
  use SkollerWeb, :controller

  import SkollerWeb.Helpers.AuthPlug

  alias Sammi.Api
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def status(conn, _params) do
    case Api.status() do
      :ok -> conn |> send_resp(204, "")
      :error -> conn |> send_resp(503, "")
    end
  end
end