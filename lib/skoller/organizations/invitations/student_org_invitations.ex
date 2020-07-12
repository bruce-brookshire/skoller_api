defmodule Skoller.Organizations.StudentOrgInvitations do
  alias __MODULE__.StudentOrgInvitation

  use ExMvc.Adapter, model: StudentOrgInvitation

  def convert_invite_to_student(student_id, phone) do
    StudentOrgInvitation
    |> Repo.get_by(phone: phone)
    |> case do
      nil -> {:ok, "Student does not exist"}
      %{} = invitation -> __MODULE__.update(invitation, %{student_id: student_id})
    end
  end

  def get_invitations_by_org_group(org_group_id) do
    StudentOrgInvitation
    |> where([i], ^org_group_id in i.group_ids)
    |> Repo.all()
  end
end
