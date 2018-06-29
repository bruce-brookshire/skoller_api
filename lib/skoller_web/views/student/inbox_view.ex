defmodule SkollerWeb.Student.InboxView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.InboxView
  alias SkollerWeb.Class.ChatPostView
  alias SkollerWeb.Student.Inbox.ResponseView
  alias SkollerWeb.Class.ChatPostView

  def render("index.json", %{inbox: inbox}) do
    render_many(inbox, InboxView, "inbox.json")
  end

  def render("inbox.json", %{inbox: %{chat_post: chat_post, star: star, color: color, response: response}}) do
    %{
      chat_post: render_one(chat_post, ChatPostView, "chat_post_short.json"),
      color: color,
      response: render_one(response, ResponseView, "response.json"),
      is_read: star.is_read
    }
  end

  def render("inbox.json", %{inbox: %{star: star, color: color, parent_post: parent, response: response}}) do
    %{
      chat_post: render_one(parent, ChatPostView, "chat_post_short.json"),
      color: color,
      response: render_one(response, ResponseView, "response.json"),
      is_read: star.is_read
    }
  end
end