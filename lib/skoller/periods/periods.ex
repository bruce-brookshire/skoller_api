defmodule Skoller.Periods do

  alias Skoller.Schools.ClassPeriod
  alias Skoller.Repo

  import Ecto.Query
  
  def get_periods_by_school_id(school_id, params \\ %{}) do
    from(period in ClassPeriod)
    |> where([period], period.school_id == ^school_id)
    |> filter(params)
    |> Repo.all()
  end

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