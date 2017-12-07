defmodule Classnavapi.Class.AbandonedLock do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.AbandonedLock

  schema "class_abandoned_locks" do
    field :class_lock_section_id, :id
    field :class_id, :id
    field :user_id, :id

    timestamps()
  end

  @req_fields [:class_lock_section_id, :class_id, :user_id]
  @all_fields @req_fields

  @doc false
  def changeset(%AbandonedLock{} = abandoned_lock, attrs) do
    abandoned_lock
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
