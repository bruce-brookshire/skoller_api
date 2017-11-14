defmodule Classnavapi.Class.StudentAssignment do
  
    @moduledoc """
    
    Changeset and schema for student_assignments
  
    """
  
    use Ecto.Schema
    import Ecto.Changeset
    alias Classnavapi.Class.Assignment
    alias Classnavapi.Class.StudentAssignment
    alias Classnavapi.Class.StudentClass
    alias Classnavapi.Class.Weight
  
    schema "student_assignments" do
      field :due, :date
      field :name, :string
      field :weight_id, :id
      field :student_class_id, :id
      field :assignment_id, :id
      field :grade, :decimal
      belongs_to :student_class, StudentClass, define_field: false
      belongs_to :weight, Weight, define_field: false
      belongs_to :assignment, Assignment, define_field: false
  
      timestamps()
    end
  
    @req_fields [:due, :name, :weight_id, :student_class_id]
    @opt_fields [:assignment_id, :grade]
    @all_fields @req_fields ++ @opt_fields

    @req_grd_fields [:grade]
    @grd_fields @req_grd_fields
  
    @doc false
    def changeset(%StudentAssignment{} = assignment, attrs) do
      assignment
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
      |> foreign_key_constraint(:student_class_id)
      |> foreign_key_constraint(:weight_id)
    end

    def grade_changeset(%StudentAssignment{} = assignment, attrs) do
      assignment
      |> cast(attrs, @grd_fields)
      |> validate_required(@req_grd_fields)
    end
  end
  