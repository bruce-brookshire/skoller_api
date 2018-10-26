defmodule SkollerWeb.Api.V1.Assignment.Reminder.TopicController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.AssignmentReminders
  alias SkollerWeb.Assignment.ReminderNotification.TopicView

  import SkollerWeb.Plugs.Auth

  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    topics = AssignmentReminders.get_assignment_message_topics()
    conn |> render(TopicView, "index.json", topics: topics)
  end

end