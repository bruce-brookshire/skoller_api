defmodule Skoller.FieldsOfStudy do
  @moduledoc """
  Context module for fields of study.
  """

  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Creates a field of study

  ## Returns
  `{:ok, Skoller.FieldsOfStudy.FieldOfStudy}` or `{:error, Ecto.Changeset}`
  """
  def create_field_of_study(params) do
    FieldOfStudy.changeset(%FieldOfStudy{}, params)
    |> Repo.insert()
  end

  @doc """
  Gets a field of study.

  ## Returns
  `Skoller.FieldsOfStudy.FieldOfStudy` or `Ecto.NoResultsError`
  """
  def get_field_of_study!(id) do
    Repo.get!(FieldOfStudy, id)
  end

  @doc """
  Updates a field of study

  ## Returns
  `{:ok, Skoller.FieldsOfStudy.FieldOfStudy}` or `{:error, Ecto.Changeset}`
  """
  def update_field_of_study(field_old, params) do
    FieldOfStudy.changeset(field_old, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of fields of study.

  ## Params
   * `%{"field_name" => field_name}`, contains filter on name

  ## Returns
  `[Skoller.FieldsOfStudy.FieldOfStudy]` or `[]`
  """
  def get_fields_of_study_with_filter(params) do
    from(fs in FieldOfStudy)
    |> filter(params)
    |> Repo.all()
  end

  @doc """
  Returns the `Skoller.FieldsOfStudy.FieldOfStudy` and a count of `Skoller.Students.Student`

  ## Examples

      iex> Skoller.Students.get_field_of_study_count_by_school_id()
      [{field: %Skoller.FieldsOfStudy.FieldOfStudy, count: num}]

  """
  def get_field_of_study_count() do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> group_by([fs, st], [fs.field, fs.id])
    |> select([fs, st], %{field: fs, count: count(st.id)})
    |> Repo.all()
  end

  defp filter(query, %{} = params) do
    query
    |> name_filter(params)
  end

  defp name_filter(query, %{"field_name" => filter}) do
    filter = "%" <> filter <> "%"
    query
    |> where([fs], ilike(fs.field, ^filter))
  end
  defp name_filter(query, _), do: query
end