defmodule Skoller.Organizations.OrgStudents do
  alias __MODULE__.OrgStudent
  alias Skoller.StudentAssignments.StudentClasses, as: SAStudentClasses
  alias Skoller.StudentClasses
  alias Skoller.EnrolledStudents
  alias Skoller.Schools.School
  alias Skoller.Organizations.IntensityScore

  use ExMvc.Adapter, model: OrgStudent

  def get_by_params(query_params) when is_map(query_params) do
    fields = Model.__schema__(:fields) |> Enum.map(&to_string/1)

    query_params
    |> Map.take(fields)
    |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
    |> get_by_params()
  end

  def get_by_params(query_params) when is_list(query_params) do
    from(m in Model, where: ^query_params)
    |> Repo.all()
    |> Enum.map(&preload/1)
    |> Enum.map(&fetch_student_assignments/1)
  end

  defp fetch_student_assignments(
         %{student_id: student_id, student: %{primary_school_id: s_id}} = student
       ) do
    sa = SAStudentClasses.get_student_assignments(student_id)
    cl = student_id
    |> EnrolledStudents.get_enrolled_classes_by_student_id()
    |> Enum.map(fn cl ->  Map.put(cl, :grade, StudentClasses.get_class_grade(cl.id)) end)

    tz =
      case Repo.get(School, s_id || 0) do
        %{timezone: tz} -> tz
        nil -> "America/Chicago"
      end

    %{student | intensity_score: IntensityScore.create_intensity_scores(sa, tz), assignments: sa, classes: cl}
  end
end
