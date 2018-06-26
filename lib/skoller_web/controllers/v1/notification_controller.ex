defmodule SkollerWeb.Api.V1.NotificationController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Notification.ManualLog
  alias SkollerWeb.Helpers.NotificationHelper
  alias SkollerWeb.NotificationView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def syllabus(conn, _params) do
    Task.start(NotificationHelper, :send_needs_syllabus_notifications, [])
    conn |> send_resp(204, "")
  end

  def custom(conn, %{"message" => msg, "password" => password}) do
    if Comeonin.Bcrypt.checkpw(password, conn.assigns[:user].password_hash) do
      if msg |> String.length > 400 do
        conn
        |> send_resp(422, "")
      else
        Task.start(NotificationHelper, :send_custom_notification, [msg])
        conn |> send_resp(204, "")
      end
    else
      conn
        |> send_resp(401, "")
    end
  end

  def index(conn, _params) do
    logs = Repo.all(ManualLog)
    render(conn, NotificationView, "index.json", notifications: logs)
  end
end