defmodule Skoller.Organizations.StudentOrgInvitations.StudentOrgInvitation do
  use Ecto.Schema

  alias Skoller.Classes.Class
  alias Skoller.Students.Student
  alias Skoller.Organizations.Organization

  schema "student_org_invitations" do
    field :phone, :string
    field :email, :string
    field :name_first, :string
    field :name_last, :string
    field :class_ids, {:array, :integer}, default: []
    field :group_ids, {:array, :integer}, default: []

    field :classes, {:array, :map}, default: [], virtual: true

    belongs_to :student, Student
    belongs_to :organization, Organization

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[organization_id]a, opt_fields: ~w[student_id phone email name_first name_last class_ids group_ids]a

  def changeset(%__MODULE__{} = model, params) do
    super(model, params)
    |> unique_constraint(:student_id, name: :student_org_invitations_student_id_organization_id_index)
    |> unique_constraint(:phone, name: :student_org_invitations_phone_organization_id_index)
  end
end
