defmodule Skoller.FieldsOfStudy do
  alias Skoller.FieldsOfStudy.FieldOfStudy
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

  def get_fields_of_study_with_filter(params) do
    from(fs in FieldOfStudy)
    |> filter(params)
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