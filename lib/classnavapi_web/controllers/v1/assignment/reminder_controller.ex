defmodule ClassnavapiWeb.Api.V1.Assignment.ReminderController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Assignments
  alias ClassnavapiWeb.Assignment.ReminderNotificationView

  import ClassnavapiWeb.Helpers.AuthPlug

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, params) do
    case Assignments.add_assignment_message(params) do
      {:ok, reminder_notification} ->
        conn |> render(ReminderNotificationView, "show.json", reminder_notification: reminder_notification)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    rn = Assignments.get_assignment_messages()
    conn |> render(ReminderNotificationView, "index.json", reminder_notifications: rn)
  end

  def delete(conn, %{"id" => id}) do
    case Assignments.delete_assignment_messages(id) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end