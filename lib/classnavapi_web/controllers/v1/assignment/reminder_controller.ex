defmodule ClassnavapiWeb.Api.V1.Assignment.ReminderController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Assignments
  alias ClassnavapiWeb.Assignment.ReminderNotificationView

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
end