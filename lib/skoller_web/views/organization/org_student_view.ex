defmodule SkollerWeb.Organization.OrgStudentView do
  alias Skoller.Organizations.OrgStudents.OrgStudent

  use ExMvc.View, model: OrgStudent

  def render("show.json", %{model: org_student}) do
    student = org_student.student |> Map.take([:name_first, :name_last, :id])

    %{
      org_group_students: render_association(org_student.org_group_students),
      org_groups: render_association(org_student.org_groups),
      student: student,
      student_id: org_student.student_id,
      id: org_student.id
    }
  end

  def render(name, content), do: super(name, content)
end
