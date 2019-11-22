defmodule SkollerWeb.SkollerJobs.JobView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobView

  @simple_types [:job_profile_status, :ethnicity_type, :degree_type]
  @activity_types [
    :volunteer_activities,
    :club_activities,
    :achievement_activities,
    :experience_activities
  ]

  def render("show.json", %{profile: profile}) do
    profile
    |> Map.take([
      :id,
      :wakeup_date,
      :alt_email,
      :state_code,
      :regions,
      :short_sell,
      :skills,
      :work_auth,
      :sponsorship_required,
      :played_sports,
      :transcript_url,
      :resume_url,
      :social_links,
      :update_at_timestamps,
      :personality,
      :company_values,
      :gpa,
      :act_score,
      :sat_score,
      :startup_interest,
      :gender,
      :veteran,
      :disability,
      :first_gen_college,
      :fin_aid,
      :pell_grant,
      :career_interests,
      :job_profile_status,
      :ethnicity_type,
      :degree_type,
      :volunteer_activities,
      :club_activities,
      :achievement_activities,
      :experience_activities,
      :user_id
    ])
    |> Enum.map(&convert_object_parts/1)
    |> Map.new()
  end

  def render("index.json", %{profiles: profiles}),
    do: render_many(profiles, JobView, "show.json", as: :profiles)

  defp convert_object_parts({key, nil}), do: {key, nil}

  defp convert_object_parts({key, list} = entry) when is_list(list) and key in @activity_types,
    do: {key, Enum.map(list, &convert_activity_parts/1)}

  defp convert_object_parts({key, entry}) when key in @simple_types,
    do: {key, convert_type_parts(entry)}

  defp convert_object_parts(entry), do: entry

  defp convert_type_parts(entry),
    do: Map.take(entry, [:id, :name])

  defp convert_activity_parts(entry),
    do:
      Map.take(entry, [
        :id,
        :name,
        :description,
        :organization_name,
        :start_date,
        :end_date,
        :career_activity_type_id,
        :inserted_at,
        :updated_at
      ])
end
