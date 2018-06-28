defmodule Skoller.Locks.Lock do
  @moduledoc false

  # @weight_lock 100
  # @assignment_lock 200
  # @review_lock 300

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section

  schema "class_locks" do
    field :is_completed, :boolean, default: false
    field :class_lock_section_id, :id
    field :class_id, :id
    field :user_id, :id
    belongs_to :class_lock_section, Section, define_field: false

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
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:class_lock_section_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:class_lock, name: :class_locks_class_id_class_lock_section_id_index)
  end
end
