defmodule Skoller.Organizations.Organization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Schools.School
  alias Skoller.CustomSignups.Link
  alias Skoller.Organizations.OrgSchool

  schema "organizations" do
    field :name, :string
    field :custom_signup_link_id, :id
    field :color, :string
    field :logo_url, :string
    belongs_to :custom_signup_link, Link, define_field: false

    many_to_many :schools, School, join_through: OrgSchool
    has_many :org_schools, OrgSchool, on_replace: :delete


    timestamps()
  end

  @req_fields ~w[name custom_signup_link_id]a
  @opt_fields ~w[color logo_url]a
  @all_fields @req_fields ++ @opt_fields

  @upd_fields ~w[name color logo_url]a
  @upd_all @upd_fields

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> cast_assoc(:org_schools)
  end

  @doc false
  def update_changeset(organization, attrs) do
    organization
    |> cast(attrs, @upd_all)
    |> validate_required(@req_fields)
    |> cast_assoc(:org_schools)
  end
end
