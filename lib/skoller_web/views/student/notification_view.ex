defmodule SkollerWeb.Student.NotificationView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.NotificationView
  alias SkollerWeb.Student.InboxView
  alias SkollerWeb.Assignment.ModView
  alias SkollerWeb.Assignment.PostView

  def render("index.json", %{notifications: notifications}) do
    render_many(notifications, NotificationView, "notification.json")
  end

  def render("notification.json", %{notification: %{inbox: inbox}}) do
    render_one(inbox, InboxView, "inbox.json")
  end

  def render("notification.json", %{notification: %{mod: mod}}) do
    render_one(mod, ModView, "mod.json")
  end

  def render("notification.json", %{notification: %{assignment_post: assignment_post}}) do
    render_one(assignment_post, PostView, "post-detail.json")
  end
end