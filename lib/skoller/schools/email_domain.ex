defmodule Skoller.Schools.EmailDomain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "school_email_domains" do
    field :email_domain, :string
    field :school_id, :id

    timestamps()
  end

  @req_fields [:school_id, :email_domain]
  @all_fields @req_fields

  @doc false
  def changeset(email_domain, attrs) do
    email_domain
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
