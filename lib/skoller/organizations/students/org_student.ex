defmodule Skoller.Organizations.OrgStudents.OrgStudent do
  use Ecto.Schema
  alias Skoller.Students.Student
  alias Skoller.Organizations.Organization
  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass

  schema "org_students" do
    field(:intensity_score, :map, virtual: true)

    belongs_to :student, Student
    belongs_to :organization, Organization

    has_many :org_group_students, OrgGroupStudent
    has_many :org_groups, through: [:org_group_students, :org_group]
    has_many :users, through: [:student, :users]
    has_many :classes, StudentClass
    has_many :assignments, StudentAssignment

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[student_id organization_id]a
end
