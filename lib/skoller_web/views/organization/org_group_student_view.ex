defmodule SkollerWeb.Organization.OrgGroupStudentView do
  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent

  use ExMvc.View, model: OrgGroupStudent

  def render("show.json", %{model: org_group_student}) do
    student = org_group_student.student |> Map.take([:name_first, :name_last, :id])

    %{
      org_student: render_association(org_group_student.org_student),
      student: student,
      org_student_id: org_group_student.org_student_id,
      id: org_group_student.id
    }
  end

  def render(name, content), do: super(name, content)
end
