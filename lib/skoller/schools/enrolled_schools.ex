defmodule Skoller.EnrolledSchools do
  @moduledoc """
  Context module for enrolled schools.
  """

  alias Skoller.Repo
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.Classes.Schools
  alias Skoller.EnrolledStudents
  alias Skoller.ClassStatuses.Schools, as: ClassStatuses

  import Ecto.Query

  @doc """
  Returns the `Skoller.Schools.School` and a count of `Skoller.Students.Student` as well as the count of classes in each status

  ## Examples

      iex> Skoller.Students.get_schools()
      [{school: %Skoller.Schools.School, students: num}]

  """
  def get_schools_with_enrollment(filter \\ %{}) do
    from(school in School)
    |> join(:left, [school], student in subquery(get_school_enrollment_subquery()), on: student.school_id == school.id)
    |> filter(filter)
    |> select([school, student], %{school: school, students: fragment("coalesce(?, 0)", student.count)})
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :classes, ClassStatuses.get_status_counts(&1.school.id)))
  end

  @doc """
  Returns a subquery that provides a unique list of `Skoller.Schools.School` ids and `Skoller.Students.Student` ids

  """
  def get_student_schools_subquery() do
    from(student in Student)
    |> join(:inner, [student], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.student_id == student.id)
    |> join(:inner, [student, sc], class in subquery(Schools.get_school_from_class_subquery()), on: sc.class_id == class.class_id)
    |> distinct([student, sc, class], [student.id, class.school_id])
    |> select([student, sc, class], %{student_id: student.id, school_id: class.school_id})
  end

  # gets count of enrollment per school.
  defp get_school_enrollment_subquery() do
    from(s in subquery(get_student_schools_subquery()))
    |> group_by([s], s.school_id)
    |> select([s], %{school_id: s.school_id, count: count(s.student_id)})
  end

  defp filter(query, filter) do
    query
    |> name_filter(filter)
    |> chat_disabled_filter(filter)
  end

  defp name_filter(query, %{"name" => name}) do
    filter = "%" <> name <> "%"
    query
    |> where([s], ilike(s.name, ^filter))
  end
  defp name_filter(query, _params), do: query

  defp chat_disabled_filter(query, %{"chat_disabled" => "true"}) do
    query
    |> where([s], not s.is_chat_enabled)
  end
  defp chat_disabled_filter(query, _params), do: query
end