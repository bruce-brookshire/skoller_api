defmodule Classnavapi.Class.StudentClass do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentClass


  schema "student_classes" do
    field :student_id, :id
    field :class_id, :id

    timestamps()
  end

  @req_fields [:student_id, :class_id]
  @all_fields @req_fields

  @doc false
  def changeset(%StudentClass{} = student_class, attrs) do
    student_class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:student_class, name: :student_classes_student_id_class_id_index)
  end
end
