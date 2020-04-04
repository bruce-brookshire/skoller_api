defmodule Skoller.Organization.OrgGroupStudents.OrgGroupStudent do
  use Ecto.Schema

  alias Skoller.Organizations.OrgStudents.OrgStudent
  alias Skoller.Organizations.OrgGroups.OrgGroup

  schema "org_group_students" do
    belongs_to :org_student, OrgStudent
    belongs_to :org_group, OrgGroup
  end
end