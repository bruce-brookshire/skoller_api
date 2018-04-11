defmodule Skoller.Schools do
  @moduledoc """
  The Schools context.
  """

  alias Skoller.Repo
  alias Skoller.Schools.School
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Timezone

  import Ecto.Query

  @doc """
    Creates a `Skoller.Schools.School`
  """
  def create_school(params) do
    {:ok, timezone} = Timezone.get_timezone(params["adr_locality"], params["adr_country"], params["adr_region"])
    %School{}
    |> School.changeset_insert(params)
    |> Ecto.Changeset.change(%{timezone: timezone})
    |> Repo.insert()
  end

  @doc """
    Gets a `Skoller.Schools.School` by id
  """
  def get_school_by_id!(id) do
    Repo.get!(School, id)
  end

  def update_school(school_old, params) do
    school_old
    |> School.changeset_update(params)
    |> Repo.update()
  end

  @doc """
    Gets a `Skoller.Schools.School` from a `Skoller.Schools.ClassPeriod`
  """
  def get_school_from_period(class_period_id) do
    from(cp in ClassPeriod)
    |> join(:inner, [cp], s in School, s.id == cp.school_id)
    |> where([cp], cp.id == ^class_period_id)
    |> select([cp, s], s)
    |> Repo.one()
  end

  @doc """
    Gets a list of `Skoller.Schools.School` with filters.

    ##Filters
      * short_name
        * Gets schools by short_name (for scripting generally).
  """
  def get_schools(filters \\ %{}) do
    from(school in School)
    |> filter(filters)
    |> Repo.all()
  end

  defp filter(query, params) do
    query
    |> short_name_filter(params)
  end

  defp short_name_filter(query, %{"short_name" => short_name}) do
    query
    |> where([school], school.short_name == ^short_name)
  end
  defp short_name_filter(query, _params), do: query
end