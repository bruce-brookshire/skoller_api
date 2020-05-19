defmodule SkollerWeb.Api.V1.Organization.StudentOrgInvitationController do
  alias Skoller.Organizations.StudentOrgInvitations
  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias Skoller.Organizations.OrgStudents

  use ExMvc.Controller, adapter: StudentOrgInvitations, view: StudentOrgInvitationView

  def respond(conn, %{"student_org_invitation_id" => invite_id, "accepts" => accepts}) do
    case StudentOrgInvitations.get_by_id(invite_id) do
      nil ->
        conn |> send_resp(401, "Not found")

      %{student_id: _, organization_id: _} = invite ->
        if accepts,
          do: Map.take(invite, [:student_id, :organization_id]) |> OrgStudents.create()

        StudentOrgInvitations.delete(invite)
        send_resp(conn, 204, "")
    end
  end
end
