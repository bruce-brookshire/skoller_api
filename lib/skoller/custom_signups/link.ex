defmodule Skoller.CustomSignups.Link do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.CustomSignups.Link

  schema "custom_signup_links" do
    field :end, :utc_datetime
    field :link, :string
    field :name, :string
    field :start, :utc_datetime

    timestamps()
  end

  @req_fields [:name, :link]
  @opt_fields [:start, :end]
  @all_fields @req_fields ++ @opt_fields

  @req_upd [:name]
  @opt_upd [:start, :end]
  @all_upd @req_upd ++ @opt_upd

  @doc false
  def changeset(%Link{} = link, attrs) do
    link
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:link, name: :unique_signup_link_index)
  end

  @doc false
  def changeset_update(%Link{} = link, attrs) do
    link
    |> cast(attrs, @all_upd)
    |> validate_required(@req_upd)
  end
end
