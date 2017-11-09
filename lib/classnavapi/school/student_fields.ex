defmodule Classnavapi.School.StudentFields do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School.StudentFields

  schema "student_fields_of_study" do
    field :field_of_study_id, :id
    field :student_id, :id

    timestamps()
  end

  @req_fields [:field_of_study_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%StudentFields{} = student_fields, attrs) do
    student_fields
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
