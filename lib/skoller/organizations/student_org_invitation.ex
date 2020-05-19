defmodule Skoller.Organizations.StudentOrgInvitations.StudentOrgInvitation do
  use Ecto.Schema

  alias Skoller.Students.Student
  alias Skoller.Organizations.Organization

  schema "student_org_invitations" do
    belongs_to :student, Student
    belongs_to :organization, Organization
  end

  use ExMvc.ModelChangeset, req_fields: ~w[student_id organization_id]a
end