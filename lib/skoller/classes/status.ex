defmodule Skoller.Classes.Status do
  @moduledoc false

  # @syllabus_status 200
  # @weight_status 300
  # @assignment_status 400
  # @review_status 500
  # @help_status 600
  # @complete_status 700
  # @change_status 800

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Classes.Status

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "class_statuses" do
    field :is_complete, :boolean, default: false
    field :name, :string
    field :is_maintenance, :boolean, default: false

    timestamps()
  end

  @req_fields [:id, :name, :is_maintenance, :is_complete]
  @all_fields @req_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
