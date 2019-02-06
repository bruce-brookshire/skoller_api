defmodule SkollerWeb.AnalyticsView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.AnalyticsView

  def render("show.json", %{analytics: analytics}) do
    render_one(analytics, AnalyticsView, "analytics.json")
  end

  def render("index-communities.json", %{communities: communities}) do
    render_many(communities, AnalyticsView, "community.json")
  end

  def render("analytics.json", %{analytics: analytics}) do
    analytics
  end

  def render("community.json", %{analytics: %{created_on: created_on} = community}) do
    created_on = created_on |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()
    IO.inspect created_on
    community |> Map.put(:created_on, created_on)
  end
end
