defmodule SkollerWeb.Api.V1.Assignment.ReminderController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.AssignmentReminders
  alias SkollerWeb.Assignment.ReminderNotificationView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, params) do
    case AssignmentReminders.add_assignment_message(params) do
      {:ok, reminder_notification} ->
        conn |> render(ReminderNotificationView, "show.json", reminder_notification: reminder_notification)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    rn = AssignmentReminders.get_assignment_messages()
    conn |> render(ReminderNotificationView, "index.json", reminder_notifications: rn)
  end

  def delete(conn, %{"id" => id}) do
    case AssignmentReminders.delete_assignment_messages(id) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end