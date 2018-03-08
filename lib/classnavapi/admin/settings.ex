defmodule Classnavapi.Admin.Settings do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Admin.Settings

  @primary_key {:name, :string, []}
  schema "admin_settings" do
    field :value, :string

    timestamps()
  end

  @req_fields [:name, :value]
  @all_fields @req_fields

  @doc false
  def changeset(%Settings{} = auto_update, attrs) do
    auto_update
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
