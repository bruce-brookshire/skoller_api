defmodule Skoller.Professors do
  @moduledoc """
  Context module for professors
  """

  alias Skoller.Repo
  alias Skoller.Professors.Professor

  import Ecto.Query

  @doc """
  Creates a professor

  ## Returns
  `{:ok, Skoller.Professors.Professor}` or `{:error, Ecto.Changeset}`
  """
  def create_professor(params) do
    Professor.changeset_insert(%Professor{}, params)
    |> Repo.insert()
  end

  @doc """
  Updates a professor

  ## Returns
  `{:ok, Skoller.Professors.Professor}` or `{:error, Ecto.Changeset}`
  """
  def update_professor(professor_old, params) do
    Professor.changeset_update(professor_old, params)
    |> Repo.update()
  end

  @doc """
  Gets a professor by id

  ## Returns
  `Skoller.Professors.Professor` or `Ecto.NoResultsError`
  """
  def get_professor_by_id!(id) do
    Repo.get!(Professor, id)
  end

  @doc """
  Gets professors by school

  ## Params
   * %{"professor_name" => professor_name}, filters on professor name.

  ## Returns
  `[Skoller.Professors.Professor]` or `[]`
  """
  def get_professors(school_id, params \\ %{}) do
    from(p in Professor)
    |> where([p], p.school_id == ^school_id)
    |> filters(params)
    |> Repo.all()
  end

  @doc """
  Gets professor by name and school

  ## Returns
  `Skoller.Professors.Professor` or `nil`
  """
  def get_professor_by_name(name_first, name_last, school_id) do
    name_first = name_first |> String.trim()
    name_last = name_last |> String.trim()
    from(p in Professor)
    |> where([p], p.name_first == ^name_first and p.name_last == ^name_last and p.school_id == ^school_id)
    |> limit(1)
    |> Repo.one()
  end

  defp filters(query, params) do
    query
    |> name_filter(params)
  end

  defp name_filter(query, %{"professor_name" => professor_name}) do
    prof_filter = professor_name <> "%"
    query
    |> where([p], ilike(p.name_first, ^prof_filter) or ilike(p.name_last, ^prof_filter))
  end
  defp name_filter(query, _params), do: query
end