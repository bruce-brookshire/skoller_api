defmodule Skoller.Professors do

  alias Skoller.Repo
  alias Skoller.Professors.Professor

  import Ecto.Query

  def create_professor(params) do
    Professor.changeset_insert(%Professor{}, params)
    |> Repo.insert()
  end

  def update_professor(professor_old, params) do
    Professor.changeset_update(professor_old, params)
    |> Repo.update()
  end

  def get_professor_by_id!(id) do
    Repo.get!(Professor, id)
  end

  def get_professors(class_period_id, params \\ %{}) do
    from(p in Professor)
    |> where([p], p.class_period_id == ^class_period_id)
    |> filters(params)
    |> Repo.all()
  end

  def get_professor_by_name(name_first, name_last, class_period_id) do
    name_first = name_first |> String.trim()
    name_last = name_last |> String.trim()
    from(p in Professor)
    |> where([p], p.name_first == ^name_first and p.name_last == ^name_last and p.class_period_id == ^class_period_id)
    |> limit(1)
    |> Repo.one()
  end

  defp filters(query, params) do
    query
    |> name_filter(params)
  end

  defp name_filter(query, %{"professor.name" => professor_name}) do
    prof_filter = professor_name <> "%"
    query
    |> where([p], ilike(p.name_first, ^prof_filter) or ilike(p.name_last, ^prof_filter))
  end
  defp name_filter(query, _params), do: query
end