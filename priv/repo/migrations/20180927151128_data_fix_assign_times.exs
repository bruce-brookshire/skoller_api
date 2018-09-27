defmodule Skoller.Repo.Migrations.DataFixAssignTimes do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Classes.Schools

  import Ecto.Query

  use Timex

  def change do
    assignment = from(a in Assignment)
    |> join(:inner, [a], c in Class, a.class_id == c.id)
    |> join(:inner, [a, c], s in subquery(Schools.get_school_from_class_subquery()), c.id == s.class_id)
    |> join(:inner, [a, c, s], sch in School, sch.id == s.school_id)
    |> where([a], fragment("?::time", a.due) == fragment("'00:00:00'::time"))
    |> where([a, c, s, sch], not(is_nil(sch.timezone)))
    |> select([a, c, s, sch], %{assignment: a, school: sch})
    |> Repo.all()

    student_assignment = from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sa.student_class_id == sc.id)
    |> join(:inner, [sa, sc], s in subquery(Schools.get_school_from_class_subquery()), sc.class_id == s.class_id)
    |> join(:inner, [sa, sc, s], sch in School, sch.id == s.school_id)
    |> where([sa], fragment("?::time", sa.due) == fragment("'00:00:00'::time"))
    |> where([sa, sc, s, sch], not(is_nil(sch.timezone)))
    |> select([sa, sc, s, sch], %{assignment: sa, school: sch})
    |> Repo.all()

    assignments = assignment ++ student_assignment

    assignments |> Enum.each(&set_due_time(&1))
  end

  defp set_due_time(%{assignment: assign, school: sc}) do
    new_date = assign.due
    |> DateTime.to_date
    |> Timex.to_datetime(sc.timezone)
    |> Timex.to_datetime()
    assign
    |> Ecto.Changeset.change(%{due: new_date})
    |> Repo.update()
  end
end
