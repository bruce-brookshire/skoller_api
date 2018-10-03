defmodule Skoller.EmailTypes.EmailType do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.EmailTypes.EmailType

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "email_types" do
    field :name, :string
    field :category, :string
    field :is_active_email, :boolean, default: true
    field :is_active_notification, :boolean, default: true
    field :send_time, :string

    timestamps()
  end

  @req_fields [:id, :name, :is_active_email, :is_active_notification, :send_time]
  @opt_fields [:category]
  @all_fields @req_fields ++ @opt_fields

  @req_upd [:is_active_email, :is_active_notification, :send_time]
  @all_upd @req_upd

  @doc false
  def changeset(%EmailType{} = email_type, attrs) do
    email_type
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  @doc false
  def update_changeset(%EmailType{} = email_type, attrs) do
    email_type
    |> cast(attrs, @all_upd)
    |> validate_required(@req_upd)
  end
end
