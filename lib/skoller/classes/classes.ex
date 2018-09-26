defmodule Skoller.Classes do
  @moduledoc """
  The Classes context.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Schools
  alias Skoller.Universities
  alias Skoller.HighSchools
  alias Skoller.Classes.Schools, as: ClassSchools
  alias Skoller.Classes.ClassStatuses

  import Ecto.Query

  @doc """
  Gets a `Skoller.Classes.Class` by id.

  ## Examples

      iex> Skoller.Classes.get_class_by_id(1)
      {:ok, %Skoller.Classes.Class{}}

  """
  def get_class_by_id(id) do
    Repo.get(Class, id)
  end

  @doc """
  Gets a `Skoller.Classes.Class` by id

  ## Examples

      iex> Skoller.Classes.get_class_by_id!(1)
      %Skoller.Classes.Class{}

  """
  def get_class_by_id!(id) do
    Repo.get!(Class, id)
  end

  @doc """
  Gets a `Skoller.Classes.Class` by id with `Skoller.Weights.Weight`

  """

  def get_full_class_by_id!(id) do
    Repo.get!(Class, id)
    |> Repo.preload([:weights])
  end

  @doc """
  Creates a `Skoller.Classes.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Periods.ClassPeriod`

  ## Behavior:
    * If there is no grade scale provided, a default is used: `%{"A" => "90", "B" => "80", "C" => "70", "D" => "60"}`
    * If `user` is passed in that is a student, will add student created class fields.

  ## Examples

      iex> Skoller.Classes.create_class(%{} = params)
      %Skoller.Classes.Class{}

  """
  def create_class(params, user \\ nil) do
    class_period_id = params |> Map.get(:class_period_id, Map.get(params, "class_period_id"))

    changeset = class_period_id
    |> Schools.get_school_from_period()
    |> get_create_changeset(params)
    |> add_student_created_class_fields(user)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:class, changeset)
    |> Ecto.Multi.run(:class_status, &ClassStatuses.check_status(&1.class, %{params: params}))
    |> Repo.transaction()
  end

  @doc """
  Updates a `Skoller.Classes.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Periods.ClassPeriod`

  ## Examples

      iex> Skoller.Classes.update_class(old_class, %{} = params)
      {:ok, %{class: %Skoller.Classes.Class{}, class_status: %Skoller.Classes.Class{}}}

  """
  def update_class(class_old, params) do
    changeset = class_old.class_period_id
    |> Schools.get_school_from_period()
    |> get_update_changeset(params, class_old)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_status, &ClassStatuses.check_status(&1.class, nil))
    |> Repo.transaction()
  end

  @doc """
  Gets a count of classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_class_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(ClassSchools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of student created classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def student_created_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(ClassSchools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_create_changeset(%{is_university: true}, params) do
    Universities.get_changeset(params)
  end
  defp get_create_changeset(%{is_university: false}, params) do
    HighSchools.get_changeset(params)
  end
  defp get_update_changeset(%{is_university: true}, params, old_class) do
    Universities.get_changeset(old_class, params)
  end
  defp get_update_changeset(%{is_university: false}, params, old_class) do
    HighSchools.get_changeset(old_class, params)
  end

  #If user is a student, set student fields on changeset.
  defp add_student_created_class_fields(changeset, user)
  defp add_student_created_class_fields(changeset, %{student: nil}), do: changeset
  defp add_student_created_class_fields(changeset, %{student: _}) do
    changeset |> Ecto.Changeset.change(%{is_student_created: true})
  end
  defp add_student_created_class_fields(changeset, _user), do: changeset
end