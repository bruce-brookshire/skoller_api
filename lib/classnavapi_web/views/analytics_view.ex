defmodule ClassnavapiWeb.AnalyticsView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.AnalyticsView

  def render("show.json", %{analytics: analytics}) do
      render_one(analytics, AnalyticsView, "analytics.json")
  end

  def render("analytics.json", %{analytics: analytics}) do
      analytics
  end
end
