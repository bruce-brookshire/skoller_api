defmodule Skoller.Schools.Timezones do
  @moduledoc """
  The School Timezone context.
  """

  alias Skoller.Assignments.Schools, as: SchoolAssignments
  alias Skoller.StudentAssignments.Schools, as: SchoolStudentAssignments
  alias Skoller.MapErrors
  alias Skoller.Repo

  use Timex

  def process_timezone_change(old_timezone, school) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:assignments, &update_assignment_due_dates(school, old_timezone, &1))
    |> Ecto.Multi.run(:student_assignments, &update_student_assignment_due_times(school, old_timezone, &1))
  end

  defp update_assignment_due_dates(school, old_timezone, _) do
    assignments = SchoolAssignments.get_school_assignments(school.id)

    status = assignments |> Enum.map(&update_assignment(&1, old_timezone, school.timezone))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp update_student_assignment_due_times(school, old_timezone, _) do
    assignments = SchoolStudentAssignments.get_school_student_assignments(school.id)

    status = assignments |> Enum.map(&update_assignment(&1, old_timezone, school.timezone))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp update_assignment(%{due: nil} = assignment, _old_timezone, _new_timezone), do: {:ok, assignment}
  defp update_assignment(assignment, old_timezone, new_timezone) do
    new_date = assignment.due
    |> Timex.to_datetime(old_timezone)
    |> DateTime.to_date
    |> Timex.to_datetime(new_timezone)
    |> Timex.to_datetime()
    assignment
    |> Ecto.Changeset.change(%{due: new_date})
    |> Repo.update()
  end
end