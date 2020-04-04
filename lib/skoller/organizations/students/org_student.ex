defmodule Skoller.Organization.OrgStudents.OrgStudent do
  use Ecto.Schema

  alias Skoller.Students.Student
  alias Skoller.Organizations.Organization

  schema "org_students" do
    belongs_to :student, Student
    belongs_to :organization, Organization
  end
end