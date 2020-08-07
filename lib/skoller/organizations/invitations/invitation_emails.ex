defmodule Skoller.Organizations.StudentOrgInvitations.InvitationEmails do
  alias Skoller.Services.SesMailer
  alias Skoller.Organizations.StudentOrgInvitations

  def send_invite_email(invited_by, org_group_id: group_id) do
    group_id
    |> StudentOrgInvitations.get_invitations_by_org_group()
    |> IO.inspect
    |> Enum.each(fn %{email: email, organization: %{name: org_name}} ->
      send_invite_email(email, org_name, invited_by)
    end)
  end

  def send_invite_email(invited_by, params) do
    params
    |> StudentOrgInvitations.get_by_params()
    |> IO.inspect
    |> Enum.each(fn %{email: email, organization: %{name: org_name}} ->
      send_invite_email(email, org_name, invited_by)
    end)
  end

  def send_reminder_email(org_group_id: org_group_id) do
    org_group_id
    |> StudentOrgInvitations.get_invitations_by_org_group()
    |> IO.inspect
    |> Enum.each(fn %{email: email, organization: %{name: org_name}} ->
      send_reminder_email(email, org_name)
    end)
  end

  def send_reminder_email(params) do
    params
    |> StudentOrgInvitations.get_by_params()
    |> IO.inspect
    |> Enum.each(fn %{email: email, organization: %{name: org_name}} ->
      send_reminder_email(email, org_name)
    end)
  end

  defp send_invite_email(email, org_name, invited_by) do
    %{
      to: email,
      form: %{
        organization_name: org_name,
        invited_by: invited_by
      }
    }
    |> SesMailer.send_individual_email("skoller_insights_invitation")
  end

  defp send_reminder_email(email, org_name) do
    %{
      to: email,
      form: %{
        organization_name: org_name
      }
    }
    |> SesMailer.send_individual_email("skoller_insights_reminder")
  end
end
