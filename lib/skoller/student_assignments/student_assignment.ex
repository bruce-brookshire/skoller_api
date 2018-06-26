defmodule Skoller.StudentAssignments.StudentAssignment do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Class.Assignment
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Class.Weight

  schema "student_assignments" do
    field :due, :utc_datetime
    field :name, :string
    field :weight_id, :id
    field :student_class_id, :id
    field :assignment_id, :id
    field :grade, :decimal
    field :is_completed, :boolean
    field :is_reminder_notifications, :boolean, default: true
    field :is_post_notifications, :boolean, default: true
    field :notes, :string
    field :is_read, :boolean, default: true
    belongs_to :student_class, StudentClass, define_field: false
    belongs_to :weight, Weight, define_field: false
    belongs_to :assignment, Assignment, define_field: false
    has_many :posts, through: [:assignment, :posts]

    timestamps()
  end

  @req_fields [:name, :student_class_id, :due]
  @opt_fields [:assignment_id, :weight_id, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @upd_req_fields [:name, :is_post_notifications, :is_reminder_notifications, :due, :is_read]
  @upd_opt_fields [:weight_id, :is_completed, :notes]
  @upd_fields @upd_opt_fields ++ @upd_req_fields

  @auto_req_fields [:name, :is_post_notifications, :is_reminder_notifications]
  @auto_opt_fields [:weight_id, :is_completed, :due]
  @auto_fields @auto_opt_fields ++ @auto_req_fields

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
    |> validate_length(:notes, max: 2000)
    |> foreign_key_constraint(:weight_id)
  end

  def changeset_update_auto(%StudentAssignment{} = assignment, attrs) do
    assignment
    |> cast(attrs, @auto_fields)
    |> validate_required(@auto_req_fields)
    |> foreign_key_constraint(:weight_id)
  end

  def grade_changeset(%StudentAssignment{} = assignment, attrs) do
    assignment
    |> cast(attrs, @grd_fields)
    |> complete_assignment()
  end

  defp complete_assignment(%Ecto.Changeset{changes: %{grade: _grade}, valid?: true} = changeset) do
    changeset |> change(%{is_completed: true})
  end
end
  