defmodule SkollerWeb.ReportView do
  use SkollerWeb, :view

  alias SkollerWeb.ReportView

  def render("index.json", %{reports: reports}) do
    render_many(reports, ReportView, "report.json")
  end

  def render("show.json", %{report: report}) do
    render_one(report, ReportView, "report.json")
  end

  def render("report.json", %{report: report}) do
    %{
      id: report.id,
      context: report.context,
      note: report.note
    }
  end
end
