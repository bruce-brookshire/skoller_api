defmodule Skoller.Classes do

  alias Skoller.Repo
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Class.Status

  import Ecto.Query

  @doc """
  Gets a `Skoller.Schools.Class` by id.

  ## Examples

      iex> Skoller.Classes.get_class_by_id(1)
      {:ok, %Skoller.Schools.Class{}

  """
  def get_class_by_id(id) do
    Repo.get(Class, id)
  end

  @doc """
  Gets a `Skoller.Schools.Class` by id

  ## Examples

      iex> Skoller.Classes.get_class_by_id!(1)
      %Skoller.Schools.Class{}

  """
  def get_class_by_id!(id) do
    Repo.get!(Class, id)
  end

  @doc """
  Returns a count of `Skoller.Schools.Class` using the id of `Skoller.Schools.ClassPeriod`

  ## Examples

      iex> val = Skoller.Classes.get_class_count_by_period(1)
      ...> Kernel.is_integer(val)
      true

  """
  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the `Skoller.Class.Status` name and a count of `Skoller.Schools.Class` in the status

  ## Examples

      iex> Skoller.Classes.get_status_counts(1)
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

  @doc """
  Gets all `Skoller.Schools.Class` in a period that share a hash (hashed from syllabus url)

  ## Examples

      iex> Skoller.Classes.get_class_from_hash("123dadqwdvsdfscxsz", 1)
      [%Skoller.Schools.Class{}]

  """
  def get_class_from_hash(class_hash, period_id) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class, period], period.id == ^period_id)
    |> where([class], class.class_upload_key == ^class_hash)
    |> Repo.all()
  end

  @doc """
  Gets class_id and school_id

  """
  def get_school_from_class_subquery() do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
end