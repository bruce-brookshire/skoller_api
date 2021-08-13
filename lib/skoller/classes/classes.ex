defmodule Skoller.Classes do
  @moduledoc """
  The Classes context.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Schools
  alias Skoller.Universities
  alias Skoller.HighSchools
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.Assignments.Mods
  alias Skoller.StudentClasses

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
    |> Repo.preload([:weights, :notes])
    |> Map.put(:students, StudentClasses.get_studentclasses_by_class(id))
    |> Map.put(:assignments, Mods.get_mod_assignments_by_class(id))
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
    |> add_created_by_fields(user, params["created_on"])

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:class, changeset)
    |> Ecto.Multi.run(:class_status, fn (_, changes) -> ClassStatuses.check_status(changes.class, %{params: params}) end)
    |> Repo.transaction()
  end

  @doc """
  Updates a `Skoller.Classes.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Periods.ClassPeriod`

  ## Examples

      iex> Skoller.Classes.update_class(old_class, %{} = params)
      {:ok, %{class: %Skoller.Classes.Class{}, class_status: %Skoller.Classes.Class{}}}

  """
  def update_class(class_old, params, user_id \\ nil) do
    changeset = class_old.class_period_id
    |> Schools.get_school_from_period()
    |> get_update_changeset(params, class_old)
    |> add_updated_by_fields(user_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_status, fn (_, changes) -> ClassStatuses.check_status(changes.class, nil) end)
    |> Repo.transaction()
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

  defp add_created_by_fields(changeset, nil, _created_on), do: changeset |> Ecto.Changeset.change(%{created_on: "System"})
  defp add_created_by_fields(changeset, user, created_on) do
    changeset |> Ecto.Changeset.change(%{created_by: user.id, updated_by: user.id, created_on: created_on})
  end

  defp add_updated_by_fields(changeset, nil), do: changeset
  defp add_updated_by_fields(changeset, user_id) do
    changeset |> Ecto.Changeset.change(%{updated_by: user_id})
  end
end
