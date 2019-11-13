defmodule SkollerWeb.SkollerJobs.CareerActivityView do
  use SkollerWeb, :view

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
        :activity_type_id,
        :description
      ])
end
