defmodule Classnavapi.School.EmailDomain do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School.EmailDomain

  schema "email_domains" do
    field :email_domain, :string
    field :is_professor_only, :boolean
    field :school_id, :id
    belongs_to :school, Classnavapi.School, define_field: false

    timestamps()
  end

  @all_fields [:email_domain, :is_professor_only]
  @req_fields [:email_domain, :is_professor_only]
  @upd_fields [:email_domain, :is_professor_only]

  @doc false
  def changeset_insert(%EmailDomain{} = email_domain, attrs) do
    email_domain
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_format(:email_domain, ~r/@/)
  end

  def changeset_update(%EmailDomain{} = email_domain, attrs) do
    email_domain
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_fields)
    |> validate_format(:email_domain, ~r/@/)
  end
end
