defmodule Classnavapi.Admin.Setting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Admin.Setting

  @primary_key {:name, :string, []}
  schema "admin_settings" do
    field :value, :string
    field :topic, :string

    timestamps()
  end

  @req_fields [:name, :value, :topic]
  @all_fields @req_fields

  @doc false
  def changeset(%Setting{} = auto_update, attrs) do
    auto_update
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
