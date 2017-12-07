defmodule Classnavapi.Class.Lock do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Lock

  schema "class_locks" do
    field :is_completed, :boolean, default: false
    field :class_lock_section_id, :id
    field :class_id, :id
    field :user_id, :id

    timestamps()
  end

  @req_fields [:class_lock_section_id, :class_id, :user_id]
  @opt_fields [:is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Lock{} = lock, attrs) do
    lock
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
