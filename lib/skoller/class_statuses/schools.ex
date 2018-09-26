defmodule Skoller.ClassStatuses.Schools do
  @moduledoc """
    A context module for class statuses in a school.
  """

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.ClassesStatuses.Status
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Returns the `Skoller.ClassesStatuses.Status` name and a count of `Skoller.Classes.Class` in the status

  ## Examples

      iex> Skoller.ClassStatuses.Schools.get_status_counts(1)
      [{status: name, count: num}]

  """
  def get_status_counts(school_id) do
    from(class in Class)
    |> join(:inner, [class], prd in ClassPeriod, class.class_period_id == prd.id)
    |> join(:full, [class, prd], status in Status, class.class_status_id == status.id)
    |> where([class, prd], prd.school_id == ^school_id)
    |> group_by([class, prd, status], [status.name])
    |> select([class, prd, status], %{status: status.name, count: count(class.id)})
    |> Repo.all()
  end
end