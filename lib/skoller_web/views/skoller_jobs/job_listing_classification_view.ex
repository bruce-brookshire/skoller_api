defmodule SkollerWeb.SkollerJobs.JobListingClassificationView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobListingClassificationView

  def render("show.json", %{classification: %{name: name}}), do: name

  def render("index.json", %{classifications: classifications}),
    do:
      render_many(classifications, JobListingClassificationView, "show.json", as: :classification)
end
