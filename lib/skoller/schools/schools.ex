defmodule Skoller.Schools do
  @moduledoc """
  The Schools context.
  """

  alias Skoller.Repo
  alias Skoller.Schools.School
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Timezone
  alias Skoller.FourDoor

  import Ecto.Query

  @doc """
    Creates a `Skoller.Schools.School`
  """
  def create_school(params) do
    params = params |> Map.put(:adr_country, "us")
    {:ok, timezone} = get_timezone(params)
    %School{}
    |> School.changeset_insert(params)
    |> Ecto.Changeset.change(%{timezone: timezone})
    |> Repo.insert()
    |> add_four_door()
  end

  @doc """
    Gets a `Skoller.Schools.School` by id
  """
  def get_school_by_id!(id) do
    school = Repo.get!(School, id)
    add_four_door({:ok, school})
  end

  def update_school(school_old, params) do
    school_old
    |> School.changeset_update(params)
    |> Repo.update()
    |> add_four_door()
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

  defp get_timezone(%{adr_locality: loc, adr_country: country, adr_region: region}) do
    call_timezone(loc, country, region)
  end
  defp get_timezone(%{"adr_locality" => loc, "adr_country" => country, "adr_region" => region}) do
    call_timezone(loc, country, region)
  end
  defp get_timezone(_params), do: {:ok, nil}

  defp call_timezone(loc, country, region) do
    Timezone.get_timezone(loc, country, region)
  end

  defp add_four_door({:ok, school}) do
    {:ok, FourDoor.get_four_door_by_school(school.id) |> Map.merge(school)}
  end
  defp add_four_door({:error, _school} = response), do: response

  defp filter(query, params) do
    query
    |> short_name_filter(params)
    |> name_filter(params)
  end

  defp name_filter(query, %{"name" => name}) do
    name_filter = name <> "%"
    query
    |> where([school], ilike(school.name, ^name_filter))
  end
  defp name_filter(query, _params), do: query

  defp short_name_filter(query, %{"short_name" => short_name}) do
    query
    |> where([school], school.short_name == ^short_name)
  end
  defp short_name_filter(query, _params), do: query
end