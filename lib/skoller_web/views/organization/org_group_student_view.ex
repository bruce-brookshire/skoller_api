defmodule SkollerWeb.Organization.OrgGroupStudentView do
  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent

  use SkollerWeb.View,
    model: OrgGroupStudent,
    single_atom: :org_group_student,
    plural_atom: :org_group_students
end
