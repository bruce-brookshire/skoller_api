defmodule SkollerWeb.AnalyticsView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.AnalyticsView

  def render("show.json", %{analytics: analytics}) do
    render_one(analytics, AnalyticsView, "analytics.json")
  end

  def render("analytics.json", %{analytics: analytics}) do
    analytics
  end
end
