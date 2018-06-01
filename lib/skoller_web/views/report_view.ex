defmodule SkollerWeb.ReportView do
  use SkollerWeb, :view

  alias SkollerWeb.ReportView
  alias Skoller.Repo
  alias SkollerWeb.UserView

  def render("index.json", %{reports: reports}) do
    render_many(reports, ReportView, "report.json")
  end

  def render("show.json", %{report: report}) do
    render_one(report, ReportView, "report.json")
  end

  def render("report.json", %{report: report}) do
    report = report |> Repo.preload(:reporter)
    %{
      id: report.id,
      context: report.context,
      note: report.note,
      is_complete: report.is_complete,
      reported_by: render_one(report.reporter, UserView, "user.json"),
      user_id: report.user_id
    }
  end
end
