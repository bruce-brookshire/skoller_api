defmodule SkollerWeb.Api.V1.Assignment.Reminder.TopicController do
  use SkollerWeb, :controller

  alias Skoller.Assignments
  alias SkollerWeb.Assignment.ReminderNotification.TopicView

  import SkollerWeb.Helpers.AuthPlug

  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    topics = Assignments.get_assignment_message_topics()
    conn |> render(TopicView, "index.json", topics: topics)
  end

end