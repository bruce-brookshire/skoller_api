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
      field :due, :utc_datetime
      field :name, :string
      field :weight_id, :id
      field :student_class_id, :id
      field :assignment_id, :id
      field :grade, :decimal
      field :is_completed, :boolean
      field :is_notifications, :boolean, default: true
      belongs_to :student_class, StudentClass, define_field: false
      belongs_to :weight, Weight, define_field: false
      belongs_to :assignment, Assignment, define_field: false
  
      timestamps()
    end
  
    @req_fields [:due, :name, :student_class_id]
    @opt_fields [:assignment_id, :weight_id, :is_completed]
    @all_fields @req_fields ++ @opt_fields

    @upd_req_fields [:due, :name, :is_notifications]
    @upd_opt_fields [:weight_id, :is_completed]
    @upd_fields @upd_opt_fields ++ @upd_req_fields

    @grd_fields [:grade]
  
    @doc false
    def changeset(%StudentAssignment{} = assignment, attrs) do
      assignment
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
      |> foreign_key_constraint(:student_class_id)
      |> foreign_key_constraint(:weight_id)
      |> foreign_key_constraint(:assignment_id)
      |> unique_constraint(:student_class_assignments, name: :student_assignments_student_class_id_assignment_id_index)
    end

    def changeset_update(%StudentAssignment{} = assignment, attrs) do
      assignment
      |> cast(attrs, @upd_fields)
      |> validate_required(@upd_req_fields)
      |> foreign_key_constraint(:weight_id)
    end

    def grade_changeset(%StudentAssignment{} = assignment, attrs) do
      assignment
      |> cast(attrs, @grd_fields)
    end
  end
  