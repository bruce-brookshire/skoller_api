defmodule ClassnavapiWeb.Api.V1.NotificationController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Notification.ManualLog
  alias ClassnavapiWeb.Helpers.NotificationHelper
  alias ClassnavapiWeb.NotificationView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def syllabus(conn, _params) do
    Task.start(NotificationHelper, :send_needs_syllabus_notifications, [])
    conn |> send_resp(200, "")
  end

  def index(conn, _params) do
    logs = Repo.all(ManualLog)
    render(conn, NotificationView, "index.json", notifications: logs)
  end
end