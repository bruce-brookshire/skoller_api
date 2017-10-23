defmodule Classnavapi.School do
  use Ecto.Schema
  import Ecto.Changeset

  alias Classnavapi.School
  alias Classnavapi.Repo

  schema "schools" do
    field :adr_city, :string
    field :adr_line_1, :string
    field :adr_line_2, :string
    field :adr_state, :string
    field :adr_zip, :string
    field :is_active, :boolean
    field :is_editable, :boolean
    field :name, :string
    field :timezone, :string
    has_many :students, Classnavapi.Student
    has_many :email_domains, School.EmailDomain, on_replace: :delete

    timestamps()
  end

  @req_fields [:name, :adr_line_1, :adr_city, :adr_state, :adr_zip, :timezone, :is_active, :is_editable]
  @opt_fields [:adr_line_2]
  @all_fields @req_fields ++ @opt_fields
  @upd_fields @all_fields

  @doc false
  def changeset_insert(%School{} = school, attrs) do
    school
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> cast_assoc(:email_domains, required: true)
  end

  def changeset_update(%School{} = school, attrs) do
    school = Repo.preload school, :email_domains

    school
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_fields)
    |> cast_assoc(:email_domains, required: true)
  end
end
