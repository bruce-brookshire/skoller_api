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
end
