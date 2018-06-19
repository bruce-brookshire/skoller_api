defmodule Skoller.Locks.Section do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Locks.Section

  @primary_key {:id, :id, []}
  schema "class_lock_sections" do
    field :name, :string
    field :is_diy, :boolean, default: true

    timestamps()
  end

  @req_fields [:id, :name, :is_diy]
  @all_fields @req_fields

  @doc false
  def changeset(%Section{} = section, attrs) do
    section
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
