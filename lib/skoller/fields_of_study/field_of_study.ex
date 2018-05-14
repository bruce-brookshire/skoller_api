defmodule Skoller.FieldsOfStudy.FieldOfStudy do

  @moduledoc """
  
  Schema and changeset for fields_of_study

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.FieldsOfStudy.FieldOfStudy

  schema "fields_of_study" do
    field :field, :string

    timestamps()
  end

  @req_fields [:field]
  @all_fields @req_fields

  @doc false
  def changeset(%FieldOfStudy{} = field_of_study, attrs) do
    field_of_study
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:field_name, name: :fields_of_study_field_index)
  end
end
