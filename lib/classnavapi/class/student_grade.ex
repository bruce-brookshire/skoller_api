defmodule Classnavapi.Class.StudentGrade do

  @moduledoc """
  
  Defines changeset and schema for student grades.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentGrade

  schema "student_grades" do
    field :grade, :decimal
    field :assignment_id, :id
    field :student_class_id, :id
    belongs_to :assignment, Classnavapi.Class.Assignment, define_field: false
    belongs_to :student_class, Classnavapi.Class.StudentClass, define_field: false

    timestamps()
  end

  @req_fields [:assignment_id, :student_class_id, :grade]
  @all_fields @req_fields

  @doc false
  def changeset(%StudentGrade{} = student_grade, attrs) do
    student_grade
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:assignment_id)
    |> foreign_key_constraint(:student_class_id)
  end
end
