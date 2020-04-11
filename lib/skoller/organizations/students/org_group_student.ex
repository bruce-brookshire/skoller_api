defmodule Skoller.Organizations.OrgGroupStudents.OrgGroupStudent do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.{
    OrgStudents.OrgStudent,
    OrgGroups.OrgGroup,
    OrgGroupStudents.OrgGroupStudent
  }

  alias Skoller.Students.Student

  schema "org_group_students" do
    belongs_to :org_student, OrgStudent
    belongs_to :org_group, OrgGroup

    has_one :student, through: [:org_student, :student_id]
  end

  @all_fields ~w[org_student_id org_group_id]a

  def insert_changset(params), do: changeset(%OrgGroupStudent{}, params)

  def changeset(%OrgGroupStudent{} = student, params),
    do: student |> cast(params, @all_fields) |> validate_required(@all_fields)
end
