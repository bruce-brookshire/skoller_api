defmodule SkollerWeb.Organization.StudentOrgInvitationView do
  alias Skoller.Organizations.{StudentOrgInvitations.StudentOrgInvitation, OrgStudents.OrgStudent}
  alias SkollerWeb.Organization.OrgStudentView

  use ExMvc.View, model: StudentOrgInvitation

  def render("invite.json", %{invite: invite}),
    do: %{invite: render_one(invite, __MODULE__, "show.json", as: :model)}

  def render("invite.json", %{org_student: org_student}),
    do: %{org_student: render_one(org_student, OrgStudentView, "show.json", as: :model)}

  def render("invites.json", %{invites: invites}) do
    Enum.map(invites, fn
      {:error, errors} ->
        errors

      {:ok, model} ->
        render_as =
          case model.__struct__ do
            OrgStudent -> :org_student
            StudentOrgInvitation -> :invite
          end

        render_one(model, __MODULE__, "invite.json", as: render_as)
    end)
  end
end
