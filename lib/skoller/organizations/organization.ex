defmodule Skoller.Organizations.Organization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.CustomSignups.Link

  schema "organizations" do
    field :name, :string
    field :custom_signup_link_id, :id
    belongs_to :custom_signup_link, Link, define_field: false

    timestamps()
  end

  @req_fields [:name, :custom_signup_link_id]
  @all_fields @req_fields

  @upd_fields [:name]
  @upd_all @upd_fields

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  @doc false
  def update_changeset(organization, attrs) do
    organization
    |> cast(attrs, @upd_all)
    |> validate_required(@upd_fields)
  end
end
