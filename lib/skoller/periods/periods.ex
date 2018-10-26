defmodule Skoller.Periods do
  @moduledoc """
  Context module for class periods
  """

  alias Skoller.Periods.ClassPeriod
  alias Skoller.Repo

  import Ecto.Query
  
  @doc """
  Gets class periods by school.

  ## Params
   * `%{"name" => period_name}`, filters period name

  ## Returns
  `[Skoller.Periods.ClassPeriod]` or `[]`
  """
  def get_periods_by_school_id(school_id, params \\ %{}) do
    from(period in ClassPeriod)
    |> where([period], period.school_id == ^school_id)
    |> where([period], period.is_hidden == false)
    |> filter(params)
    |> Repo.all()
  end

  @doc """
  Creates a period

  ## Returns
  `{:ok, Skoller.Periods.ClassPeriod}` or `{:error, Ecto.Changeset}`
  """
  def create_period(params) do
    ClassPeriod.changeset_insert(%ClassPeriod{}, params)
    |> Repo.insert()
  end

  def update_period(period_old, params) do
    ClassPeriod.changeset_update(period_old, params)
    |> Repo.update()
  end

  def get_period!(id) do
    Repo.get!(ClassPeriod, id)
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