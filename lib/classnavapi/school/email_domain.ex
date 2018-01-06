defmodule Classnavapi.School.EmailDomain do

  @moduledoc """
  
  Defines changeset and schema for email_domains.

  Email domains will be validated for format.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School.EmailDomain
  alias Classnavapi.School

  schema "email_domains" do
    field :email_domain, :string
    field :is_professor_only, :boolean
    field :school_id, :id
    belongs_to :school, School, define_field: false

    timestamps()
  end

  @req_fields [:email_domain, :is_professor_only]
  @all_fields @req_fields

  @doc false
  def changeset(%EmailDomain{} = email_domain, attrs) do
    email_domain
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_format(:email_domain, ~r/@/)
  end
end
