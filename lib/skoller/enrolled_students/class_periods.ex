defmodule Skoller.EnrolledStudents.ClassPeriods do
  @moduledoc """
  A context module for enrolled students in class periods
  """

  alias Skoller.Classes.Class
  alias Skoller.EnrolledStudents
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Returns the count of students in a given `Skoller.Periods.ClassPeriod`.

  ## Examples

      iex> val = Skoller.EnrolledStudents.ClassPeriods.get_enrollment_by_period_id(1)
      ...>Kernel.is_integer(val)
      true

  """
  def get_enrollment_by_period_id(period_id) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
    |> where([sc, c], c.class_period_id == ^period_id)
    |> distinct([sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end
end