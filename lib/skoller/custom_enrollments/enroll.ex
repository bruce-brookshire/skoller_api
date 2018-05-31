defmodule Skoller.CustomEnrollments.Enroll do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.CustomEnrollments.Enroll
  alias Skoller.Students.Student
  alias Skoller.CustomEnrollments.Link

  schema "custom_enrollments" do
    field :custom_enrollment_link_id, :id
    field :student_id, :id
    belongs_to :student, Student, define_field: false
    belongs_to :custom_enrollment_link, Link, define_field: false

    timestamps()
  end

  @doc false
  def changeset(%Enroll{} = enroll, attrs) do
    enroll
    |> cast(attrs, [])
    |> validate_required([])
  end
end
