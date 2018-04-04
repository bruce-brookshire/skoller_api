defmodule ClassnavapiWeb.Assignment.ReminderNotification.TopicView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Assignment.ReminderNotification.TopicView

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
