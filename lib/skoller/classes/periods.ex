defmodule Skoller.Classes.Periods do
  @moduledoc """
    Context module for classes and periods
  """

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Returns a count of `Skoller.Classes.Class` using the id of `Skoller.Periods.ClassPeriod`

  ## Examples

      iex> val = Skoller.Classes.Periods.get_class_count_by_period(1)
      ...> Kernel.is_integer(val)
      true

  """
  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets all `Skoller.Classes.Class` in a period that share a hash (hashed from syllabus url)

  ## Examples

      iex> Skoller.Classes.Periods.get_class_from_hash("123dadqwdvsdfscxsz", 1)
      [%Skoller.Classes.Class{}]

  """
  def get_class_from_hash(class_hash, period_id) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class, period], period.id == ^period_id)
    |> where([class], class.class_upload_key == ^class_hash)
    |> Repo.all()
  end
end