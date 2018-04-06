defmodule Skoller.School.FieldOfStudy do

  @moduledoc """
  
  Schema and changeset for fields_of_study

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.School.FieldOfStudy

  schema "fields_of_study" do
    field :field, :string
    field :school_id, :id

    timestamps()
  end

  @req_fields [:field, :school_id]
  @all_fields @req_fields

  @doc false
  def changeset(%FieldOfStudy{} = field_of_study, attrs) do
    field_of_study
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
    |> unique_constraint(:school_field, name: :fields_of_study_field_school_id_index)
  end
end
