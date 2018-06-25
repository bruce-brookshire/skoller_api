defmodule Skoller.Admin.Setting do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Admin.Setting

  # The @primary_key line overrides the auto-increment id primary key.
  # For example, this table has a primary key of name, and type string
  # in addition to the fields below.
  @primary_key {:name, :string, []}
  schema "admin_settings" do
    field :value, :string
    field :topic, :string

    timestamps()
  end

  @req_fields [:name, :value, :topic]
  @all_fields @req_fields

  @req_upd [:value]
  @upd_fields @req_upd

  @doc false
  def changeset(%Setting{} = setting, attrs) do
    setting
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  @doc false
  def changeset_update(%Setting{} = setting, attrs) do
    setting
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_upd)
  end
end
