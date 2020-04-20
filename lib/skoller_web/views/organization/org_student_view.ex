defmodule SkollerWeb.Organization.OrgStudentView do
  alias Skoller.Organizations.OrgStudents.OrgStudent
  use SkollerWeb.View, model: OrgStudent, single_atom: :org_student, plural_atom: :org_students
end