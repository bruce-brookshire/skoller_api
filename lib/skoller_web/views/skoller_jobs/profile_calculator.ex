defmodule SkollerWeb.SkollerJobs.ProfileCalculator do
  def calculate_score(%{} = profile, %{} = user) do
    base_value(profile, user)
    |> candidate_card()
    |> work_preferences()
    |> profile_pic()
    |> basic_info()
    |> personality()
    |> more_info()
    |> company_values()
    |> equal_opportunity()
    |> social_links()
    |> volunteer()
    |> strip_profile()
  end

  defp base_value(profile, user), do: {profile, user, 0.2}

  defp candidate_card(
         {%{
            gpa: gpa,
            skills: skills,
            experience_activities: e_activities,
            achievement_activities: a_activities
          } = profile, user, value}
       )
       when not (is_nil(gpa) or is_nil(skills) or length(e_activities) == 0 or
                   length(a_activities) == 0),
       do: {profile, user, value + 0.15}

  defp candidate_card(total), do: total

  defp work_preferences(
         {%{career_interests: c_interest, regions: regions, startup_interest: s_interest} =
            profile, user, value}
       )
       when not (is_nil(c_interest) or is_nil(regions) or is_nil(s_interest)),
       do: {profile, user, value + 0.1}

  defp work_preferences(total), do: total

  defp profile_pic({profile, %{avatar: avatar} = user, value}) when not is_nil(avatar),
    do: {profile, user, value + 0.1}

  defp profile_pic(total), do: total

  defp basic_info(
         {%{state_code: state_code, work_auth: work_auth, sponsorship_required: s_required} =
            profile, user, value}
       )
       when not (is_nil(state_code) or is_nil(work_auth) or is_nil(s_required)),
       do: {profile, user, value + 0.1}

  defp basic_info(total), do: total

  defp personality({%{personality: personality} = profile, user, value})
       when not is_nil(personality),
       do: {profile, user, value + 0.1}

  defp personality(total), do: total

  defp more_info(
         {%{
            played_sports: played_sports,
            act_score: a_score,
            sat_score: s_score,
            club_activities: c_activities
          } = profile, user, value}
       )
       when not (is_nil(played_sports) or is_nil(a_score) or is_nil(s_score) or
                   length(c_activities) == 0),
       do: {profile, user, value + 0.05}

  defp more_info(total), do: total

  defp company_values({%{company_values: c_values} = profile, user, value})
       when not is_nil(c_values),
       do: {profile, user, value + 0.05}

  defp company_values(total), do: total

  defp equal_opportunity(
         {%{
            ethnicity_type: e_type,
            disability: disablity,
            fin_aid: fin_aid,
            first_gen_college: f_college,
            gender: gender,
            pell_grant: p_grant,
            veteran: veteran
          } = profile, user, value}
       )
       when not (is_nil(e_type) or is_nil(disablity) or is_nil(fin_aid) or is_nil(f_college) or
                   is_nil(gender) or is_nil(p_grant) or is_nil(veteran)),
       do: {profile, user, value + 0.05}

  defp equal_opportunity(total), do: total

  defp social_links({%{social_links: s_links} = profile, user, value})
       when not is_nil(s_links),
       do: {profile, user, value + 0.05}

  defp social_links(total), do: total

  defp volunteer({%{volunteer_activities: v_activities} = profile, user, value})
       when length(v_activities) > 0,
       do: {profile, user, value + 0.05}

  defp volunteer(total), do: total

  defp strip_profile({_, _, value}), do: value
end
