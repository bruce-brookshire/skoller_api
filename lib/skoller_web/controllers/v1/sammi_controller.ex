defmodule SkollerWeb.Api.V1.SammiController do
  @moduledoc false
  
  use SkollerWeb, :controller

  import SkollerWeb.Plugs.Auth

  alias Sammi.Api
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def status(conn, _params) do
    case Api.status() do
      :ok -> conn |> send_resp(204, "")
      :error -> conn |> send_resp(503, "")
    end
  end

  def train(conn, _params) do
    Task.start(Api, :train, [])
    conn |> send_resp(204, "")
  end
end