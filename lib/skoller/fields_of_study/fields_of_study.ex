defmodule Skoller.FieldsOfStudy do
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.School.StudentField
  alias Skoller.Repo

  import Ecto.Query

  def create_field_of_study(params) do
    FieldOfStudy.changeset(%FieldOfStudy{}, params)
    |> Repo.insert()
  end

  def get_field_of_study!(id) do
    Repo.get!(FieldOfStudy, id)
  end

  def update_field_of_study(field_old, params) do
    FieldOfStudy.changeset(field_old, params)
    |> Repo.update()
  end

  def get_fields_of_study_by_school(school_id, params) do
    from(fs in FieldOfStudy)
    |> where([fs], fs.school_id == ^school_id)
    |> filter(params)
    |> Repo.all()
  end

  @doc """
  Returns the `Skoller.FieldsOfStudy.FieldOfStudy` and a count of `Skoller.Students.Student`

  ## Examples

      iex> Skoller.Students.get_field_of_study_count_by_school_id()
      [{field: %Skoller.School.FieldsOfStudy, count: num}]

  """
  def get_field_of_study_count_by_school_id(school_id) do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> where([fs], fs.school_id == ^school_id)
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