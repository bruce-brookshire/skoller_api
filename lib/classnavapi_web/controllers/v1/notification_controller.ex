defmodule ClassnavapiWeb.Api.V1.NotificationController do
  use ClassnavapiWeb, :controller

  alias ClassnavapiWeb.Helpers.NotificationHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def syllabus(conn, _params) do
    Task.start(NotificationHelper, :send_needs_syllabus_notifications, [])
    conn |> send_resp(200, "")
  end
end