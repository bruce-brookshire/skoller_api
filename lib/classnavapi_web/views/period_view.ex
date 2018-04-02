defmodule ClassnavapiWeb.PeriodView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.PeriodView

  def render("index.json", %{periods: periods}) do
    render_many(periods, PeriodView, "period.json")
  end

  def render("show.json", %{period: period}) do
    render_one(period, PeriodView, "period.json")
  end

  def render("period.json", %{period: period}) do
    %{
      id: period.id,
      name: period.name
    }
  end
end
