defmodule SkollerWeb.Assignment.ReminderNotification.TopicView do
  use SkollerWeb, :view

  alias SkollerWeb.Assignment.ReminderNotification.TopicView

  def render("index.json", %{topics: topics}) do
    render_many(topics, TopicView, "topic.json")
  end

  def render("topic.json", %{topic: topic}) do
    %{
      id: topic.id,
      name: topic.name
    }
  end
end
