defmodule SkollerWeb.Organization.OrgStudentView do
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Class.StudentClassView

  import ExMvc.View

  use SkollerWeb, :view

  def render("show.json", %{model: org_student}) do
    student =
      org_student.student
      |> Map.take([:name_first, :name_last, :phone, :id, :intensity_score])
      |> Map.put(:user, org_student.users |> List.first() |> render_association())

    %{
      org_group_students: render_association(org_student.org_group_students),
      org_groups: render_association(org_student.org_groups),
      student: student,
      student_id: org_student.student_id,
      id: org_student.id,
      intensity_score: org_student.intensity_score,
      assignments:
        render_many(
          org_student.assignments,
          StudentAssignmentView,
          "student_assignment-short.json"
        ),
      classes: Enum.map(org_student.classes, &render_class_grade/1)
    }
  end

  def render("index.json", %{models: models}),
    do: render_many(models, __MODULE__, "show.json", as: :model)

  def render_class_grade(%{grade: grade} = class),
    do:
      class
      |> render_one(StudentClassView, "student_class.json")
      |> Map.put(:grade, Decimal.to_float(Decimal.round(grade, 2)))

  def render_class_grade(class), do: render_one(class, StudentClassView, "student_class.json")
end
