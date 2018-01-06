defmodule Classnavapi.School.StudentField do

  @moduledoc """
  
  Schema and Changeset for student fields of study

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School.StudentField

  schema "student_fields_of_study" do
    field :field_of_study_id, :id
    field :student_id, :id
    belongs_to :student, Classnavapi.Student, define_field: false
    belongs_to :field_of_study, Classnavapi.School.FieldOfStudy, define_field: false

    timestamps()
  end

  @req_fields [:field_of_study_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%StudentField{} = student_fields, attrs) do
    student_fields
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
