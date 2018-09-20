defmodule Skoller.EmailTypes.EmailType do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.EmailTypes.EmailType

  schema "email_types" do
    field :name, :string

    timestamps()
  end

  @req_fields [:name]
  @all_fields @req_fields

  @doc false
  def changeset(%EmailType{} = email_type, attrs) do
    email_type
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
