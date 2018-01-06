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
    today = DateTime.utc_now()
    period = case DateTime.compare(period.start_date, today) in [:lt, :eq] and DateTime.compare(period.end_date, today) in [:gt, :eq] do
      true -> period |> Map.put(:is_active, true)
      false -> period |> Map.put(:is_active, false)
    end
    %{id: period.id,
      is_active: period.is_active,
      name: period.name,
      start_date: period.start_date,
      end_date: period.end_date}
  end
end
