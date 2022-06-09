defmodule Skoller.StudentClasses.StudentClass do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Classes.Class
  alias Skoller.Students.Student
  alias Skoller.Organizations.OrgStudents.OrgStudent

  schema "student_classes" do
    field :student_id, :id
    field :class_id, :id
    field :color, :string
    field :is_notifications, :boolean, default: true
    field :is_dropped, :boolean, default: false
    field :enrollment_link, :string
    field :enrolled_by, :id
    belongs_to :class, Class, define_field: false
    belongs_to :student, Student, define_field: false
    belongs_to :org_student, OrgStudent
    has_many :student_assignments, StudentAssignment

    timestamps()
  end

  @req_fields [:student_id, :class_id]
  @opt_fields [:color]
  @all_fields @req_fields ++ @opt_fields

  @upd_req_fields [:is_notifications]
  @upd_opt_fields [:color]
  @upd_fields @upd_req_fields ++ @upd_opt_fields

  @doc false
  def changeset(%StudentClass{} = student_class, attrs) do
    student_class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:student_id)
    |> unique_constraint(:student_class, name: :student_classes_student_id_class_id_index)
  end

  def update_changeset(%StudentClass{} = student_class, attrs) do
    student_class
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req_fields)
  end
end
