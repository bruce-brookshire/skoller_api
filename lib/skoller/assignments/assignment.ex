defmodule Skoller.Assignments.Assignment do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Assignments.Assignment
  alias Skoller.Schools.Class
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Weights.Weight

  schema "assignments" do
    field :due, :utc_datetime
    field :name, :string
    field :weight_id, :id
    field :class_id, :id
    field :from_mod, :boolean, default: false
    belongs_to :class, Class, define_field: false
    belongs_to :weight, Weight, define_field: false
    has_many :student_assignments, StudentAssignment
    has_many :posts, Skoller.AssignmentPosts.Post

    timestamps()
  end

  @req_fields [:name, :class_id]
  @opt_fields [:due, :weight_id]
  @all_fields @req_fields ++ @opt_fields

  @stu_req_fields [:name, :class_id, :due]
  @stu_opt_fields [:weight_id]
  @stu_fields @stu_req_fields ++ @stu_opt_fields

  @doc false
  def changeset(%Assignment{} = assignment, attrs) do
    assignment
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def student_changeset(%Assignment{} = assignment, attrs) do
    assignment
    |> cast(attrs, @stu_fields)
    |> validate_required(@stu_req_fields)
  end
end
