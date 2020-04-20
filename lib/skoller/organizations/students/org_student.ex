defmodule Skoller.Organizations.OrgStudents.OrgStudent do
  use Ecto.Schema
  alias Skoller.Students.Student
  alias Skoller.Organizations.Organization
  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent

  schema "org_students" do
    belongs_to :student, Student
    belongs_to :organization, Organization

    has_many :org_group_students, OrgGroupStudent
    has_many :groups, through: [:org_group_students, :group_id]
  end

  use Skoller.Changeset, req_fields: ~w[student_id organization_id]a
end
