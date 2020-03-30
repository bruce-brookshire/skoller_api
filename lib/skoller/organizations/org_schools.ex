defmodule Skoller.Organizations.OrgSchool do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Schools.School
  alias Skoller.Organizations.OrgSchool
  alias Skoller.Organizations.Organization

  schema "org_schools" do
    belongs_to :school, School
    belongs_to :organization, Organization
  end

  @fields ~w[school_id]a

  def changeset(%OrgSchool{} = school, params) do
    school
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
