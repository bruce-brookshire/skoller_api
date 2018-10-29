defmodule Skoller.Schools.EmailDomain do
  use Ecto.Schema
  import Ecto.Changeset


  schema "school_email_domains" do
    field :email_domain, :string
    field :school_id, :id

    timestamps()
  end

  @doc false
  def changeset(email_domain, attrs) do
    email_domain
    |> cast(attrs, [:email_domain])
    |> validate_required([:email_domain])
  end
end
