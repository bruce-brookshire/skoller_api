defmodule SkollerWeb.SkollerJobs.JobListingView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobListingView
  alias SkollerWeb.SkollerJobs.JobListingClassificationView

  @min_fields [
    :sender_reference,
    :position,
    :job_source,
    :advertiser_name,
    :locality,
    :region,
    :salary_minimum,
    :salary_maximum,
    :work_hours
  ]

  @detail_fields [
    :salary_currency,
    :salary_period,
    :country,
    :employment_type,
    :description_html,
    :application_url,
    :description_url,
    :job_type,
    :sell_price,
    :revenue_type,
    :advertiser_type,
    :salary_additional,
    :start_date,
    :job_source_url,
    :logo_url
  ]
  @all_fields @min_fields ++ @detail_fields

  def render("show.json", %{listing: %{classifications: classifications} = listing}),
    do:
      Map.take(listing, @all_fields)
      |> Map.put(
        :classifications,
        render_many(classifications, JobListingClassificationView, "show.json",
          as: :classification
        )
      )

  def render("show-min.json", %{listing: listing}), do: Map.take(listing, @min_fields)

  def render("index.json", %{listings: listings}),
    do: render_many(listings, JobListingView, "show.json", as: :listing)

  def render("index-min.json", %{listings: listings}),
    do: render_many(listings, JobListingView, "show-min.json", as: :listing)
end
