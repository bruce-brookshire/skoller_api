defmodule SkollerWeb.Organization.OrgGroupStudentView do
  import ExMvc.View
  use SkollerWeb, :view

  def render("show.json", %{model: org_group_student}) do
    student =
      org_group_student.student
      |> Map.take([:name_first, :name_last, :id])
      |> Map.put(:users, org_group_student.users |> IO.inspect())

    %{
      org_student: render_association(org_group_student.org_student),
      student: student,
      org_student_id: org_group_student.org_student_id,
      id: org_group_student.id
    }
  end

  def render("index.json", %{models: models}),
    do: render_many(models, __MODULE__, "show.json", as: :model)
end
