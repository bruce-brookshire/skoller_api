defmodule ClassnavapiWeb.Student.NotificationView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Student.NotificationView
  alias ClassnavapiWeb.Student.InboxView
  alias ClassnavapiWeb.Assignment.ModView

  def render("index.json", %{notifications: notifications}) do
    render_many(notifications, NotificationView, "notification.json")
  end

  def render("notification.json", %{notification: %{inbox: inbox}}) do
    render_one(inbox, InboxView, "inbox.json")
  end

  def render("notification.json", %{notification: %{mod: mod}}) do
    render_one(mod, ModView, "mod.json")
  end
end