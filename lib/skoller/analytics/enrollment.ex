defmodule Skoller.Analytics.Enrollment do
  @moduledoc """
  A context module for running analytics on student enrollment
  """

  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents
  alias Skoller.Repo

  import Ecto.Query

  @community_enrollment 2

  @doc """
  Gets the average number of classes each student has between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns a float rounded to 2 places.
  """
  def avg_classes_per_student(dates, params) do
    from(s in subquery(student_counts_subquery(dates, params)))
    |> select([s], avg(s.count))
    |> Repo.one()
    |> convert_to_float()
  end

  @doc """
  Gets a count of classes with enrollment

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def enrollment_count(dates, params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> select([sc, c, p], count(sc.class_id, :distinct))
    |> Repo.one
  end

  @doc """
  Gets a count of classes with enrollment surpassing the community threshold.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def communitites(dates, params) do
    subq = from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> group_by([sc, c, p], sc.class_id)
    |> having([sc, c, p], count(sc.id) >= @community_enrollment)
    |> select([sc], %{count: count(sc.id)})

    from(c in subquery(subq))
    |> select([c], count(c.count))
    |> Repo.one
  end

  @doc """
  Gets a count of enrolled students in each class.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_enrollment_count(params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> Repo.aggregate(:count, :id)
  end

  defp student_counts_subquery(dates, params) do
    from(s in Student)
    |> join(:left, [s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), on: s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> group_by([s, sc], sc.student_id)
    |> select([s, sc], %{count: count(sc.student_id)})
  end

  defp convert_to_float(nil), do: 0.0
  defp convert_to_float(val), do: val |> Decimal.round(2) |> Decimal.to_float()
end