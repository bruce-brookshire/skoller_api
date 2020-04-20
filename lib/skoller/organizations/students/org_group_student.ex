defmodule Skoller.Organizations.OrgGroupStudents.OrgGroupStudent do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.{
    OrgStudents.OrgStudent,
    OrgGroups.OrgGroup
  }

  schema "org_group_students" do
    belongs_to :org_student, OrgStudent
    belongs_to :org_group, OrgGroup

    has_one :student, through: [:org_student, :student_id]
  end

  use Skoller.Changeset, req_fields: ~w[org_student_id org_group_id]a
  
end
