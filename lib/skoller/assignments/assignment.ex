defmodule Skoller.Assignments.Assignment do
  @moduledoc "Assignments Assignment Schema"
  use Skoller.Schema

  schema "assignments" do
    field :due, :utc_datetime
    field :name, :string
    field :from_mod, :boolean, default: false
    field :weight_id, :id
    field :class_id, :id
    field :created_by, :id
    field :updated_by, :id
    field :created_on, :string
    belongs_to :class, Class, define_field: false
    belongs_to :weight, Weight, define_field: false
    belongs_to :created_by_user, User, define_field: false, foreign_key: :created_by
    belongs_to :updated_by_user, User, define_field: false, foreign_key: :updated_by
    has_many :student_assignments, StudentAssignment
    has_many :posts, Skoller.AssignmentPosts.Post

    timestamps()
  end

  @required ~w(name class_id)a
  @optional ~w(due weight_id)a

  @doc false
  def changeset(%__MODULE__{} = assignment, attrs) do
    assignment
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end

  def student_changeset(%__MODULE__{} = assignment, attrs) do
    assignment
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required ++ [:due])
  end
end
