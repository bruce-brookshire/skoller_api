defmodule Skoller.CustomEnrollments.Link do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.CustomEnrollments.Link

  schema "custom_enrollment_links" do
    field :end, :date
    field :link, :string
    field :name, :string
    field :start, :date

    timestamps()
  end

  @req_fields [:name, :link]
  @opt_fields [:start, :end]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Link{} = link, attrs) do
    link
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:link, name: :unique_enrollment_link_index)
  end
end
