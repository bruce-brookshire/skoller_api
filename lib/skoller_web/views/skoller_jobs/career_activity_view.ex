defmodule SkollerWeb.SkollerJobs.CareerActivityView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.CareerActivityView

  def render("show.json", %{activity: activity}),
    do:
      activity
      |> Map.take([
        :id,
        :name,
        :organization_name,
        :start_date,
        :end_date,
        :job_profile_id,
        :career_activity_type_id,
        :description
      ])

  def render("index.json", %{activities: activities}), do:
    render_many(activities, CareerActivityView, "show.json", as: :activity)
end
