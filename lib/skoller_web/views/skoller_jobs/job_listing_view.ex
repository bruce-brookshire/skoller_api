defmodule SkollerWeb.SkollerJobs.JobListingView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobListingView
  alias SkollerWeb.SkollerJobs.JobListingClassificationView

  def render("show.json", %{listing: %{classifications: classifications} = listing}),
    do:
      Map.take(listing, [
        :sender_reference,
        :position,
        :salary_currency,
        :salary_period,
        :region,
        :locality,
        :country,
        :work_hours,
        :employment_type,
        :description_html,
        :application_url,
        :description_url,
        :job_type,
        :sell_price,
        :revenue_type,
        :advertiser_name,
        :advertiser_type,
        :job_source,
        :salary_minimum,
        :salary_maximum,
        :salary_additional,
        :start_date,
        :job_source_url,
        :logo_url
      ])
      |> Map.put(:classifications, render_many(classifications, JobListingClassificationView, "show.json", as: :classification))

  def render("index.json", %{listings: listings}) do
    render_many(listings, JobListingView, "show.json", as: :listing)
  end
end
