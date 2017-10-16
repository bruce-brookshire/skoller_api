defmodule Classnavapi.School do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School


  schema "schools" do
    field :adr_city, :string
    field :adr_line_1, :string
    field :adr_line_2, :string
    field :adr_state, :string
    field :adr_zip, :string
    field :email_domain, :string
    field :email_domain_prof, :string
    field :is_active, :boolean, default: false
    field :is_editable, :boolean, default: false
    field :name, :string
    field :timezone, :string
    has_many :students, Classnavapi.Student

    timestamps()
  end

  @doc false
  def changeset(%School{} = school, attrs) do
    school
    |> cast(attrs, [:name, :adr_line_1, :adr_line_2, :adr_city, :adr_state, :adr_zip, :timezone, :email_domain, :email_domain_prof, :is_active, :is_editable])
    |> validate_required([:name, :adr_line_1, :adr_city, :adr_state, :adr_zip, :timezone, :email_domain, :is_active, :is_editable])
  end
end
