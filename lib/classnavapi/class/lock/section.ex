defmodule Classnavapi.Class.Lock.Section do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Lock.Section

  @primary_key {:id, :id, []}
  schema "class_lock_sections" do
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name]
  @all_fields @req_fields

  @doc false
  def changeset(%Section{} = section, attrs) do
    section
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
