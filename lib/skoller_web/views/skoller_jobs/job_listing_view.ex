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

  def render("show.json", %{listing: %{classifications: classifications} = listing, user: user}),
    do:
      Map.take(listing, @all_fields)
      |> generate_application_url(user)
      |> Map.put(
        :classifications,
        render_many(classifications, JobListingClassificationView, "show.json",
          as: :classification
        )
      )

  def render("show.json", %{listing: %{classifications: classifications} = listing} = params),
    do: params |> IO.inspect() |> Map.get(:listing)

  def render("show-min.json", %{listing: listing}), do: Map.take(listing, @min_fields)

  def render("index.json", %{listings: listings, user: user}),
    do: Enum.map(listings, &render(JobListingView, "show.json", listing: &1, user: user))

  def render("index-min.json", %{listings: listings}),
    do: render_many(listings, JobListingView, "show-min.json", as: :listing)

  defp generate_application_url(listing, %{student: student, job_profile: job_profile} = user) do
    url = listing.application_url
    IO.inspect is_map(student)

    require IEx; IEx.pry

    params =
      %{
        "FirstName" => student.name_first,
        "LastName" => student.name_last,
        "Mobile" => student.phone,
        "Email" => job_profile.alt_email || user.email
      }
      |> Enum.filter(&(elem(&1, 1) != nil))
      |> Enum.map(&"&#{elem(&1, 0)}=#{elem(&1, 1)}")
      |> Enum.join("")

    new_url = url <> params

    Map.put(listing, :application_url, new_url)
  end

  defp generate_application_url(listing, _), do: listing
end
