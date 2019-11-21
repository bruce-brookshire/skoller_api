defmodule SkollerWeb.SkollerJobs.JobView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobView

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
      :user_id
    ])
    |> Enum.map(&convert_object_parts/1)
    |> Map.new()
  end

  def render("index.json", %{profiles: profiles}),
    do: render_many(profiles, JobView, "show.json", as: :profiles)

  defp convert_object_parts({:degree_type, _} = entry), do: render_type_objects(entry)
  defp convert_object_parts({:ethnicity_type, _} = entry), do: render_type_objects(entry)
  defp convert_object_parts({:job_profile_status, _} = entry), do: render_type_objects(entry)
  defp convert_object_parts(entry), do: entry

  # defp convert_object_parts({:degree_type, body}), do: {:degree_type, render_type_objects(body)}

  defp render_type_objects({key, %{} = body}), do: {key, Map.take(body, [:id, :name])}
  defp render_type_objects({key, nil}), do: {key, nil}
end
