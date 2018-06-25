defmodule Skoller.Periods do
  @moduledoc """
  Context module for class periods
  """

  alias Skoller.Schools.ClassPeriod
  alias Skoller.Repo

  import Ecto.Query
  
  @doc """
  Gets class periods by school.

  ## Params
   * `%{"name" => period_name}`, filters period name

  ## Returns
  `[Skoller.Schools.ClassPeriod]` or `[]`
  """
  def get_periods_by_school_id(school_id, params \\ %{}) do
    from(period in ClassPeriod)
    |> where([period], period.school_id == ^school_id)
    |> filter(params)
    |> Repo.all()
  end

  @doc """
  Creates a period

  ## Returns
  `{:ok, Skoller.Schools.ClassPeriod}` or `{:error, Ecto.Changeset}`
  """
  def create_period(params) do
    ClassPeriod.changeset_insert(%ClassPeriod{}, params)
    |> Repo.insert()
  end

  defp filter(query, params) do
    query
    |> filter_name(params)
  end

  defp filter_name(query, %{"name" => filter}) do
    name_filter = filter <> "%"
    query |> where([period], ilike(period.name, ^name_filter))
  end
  defp filter_name(query, _params), do: query
end