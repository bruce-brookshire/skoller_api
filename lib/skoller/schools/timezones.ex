defmodule Skoller.Schools.Timezones do
  @moduledoc """
  The School Timezone context.
  """

  alias Skoller.Assignments.Schools
  alias Skoller.MapErrors
  alias Skoller.Repo

  use Timex

  def process_timezone_change(old_timezone, school) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:assignments, &update_assignment_due_dates(school, old_timezone, &1))
  end

  defp update_assignment_due_dates(school, old_timezone, _) do
    assignments = Schools.get_school_assignments(school.id)

    status = assignments |> Enum.map(&update_assignment(&1, old_timezone, school.timezone))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

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