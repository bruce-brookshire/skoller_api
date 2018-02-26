defmodule Classnavapi.Class.Status do

  @moduledoc """
  
  Defines schema and changeset for class_statuses

  The primary key is not seeded.

  """

  # @syllabus_status 200
  # @weight_status 300
  # @assignment_status 400
  # @review_status 500
  # @help_status 600
  # @complete_status 700
  # @change_status 800

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Status

  @primary_key {:id, :id, []}
  schema "class_statuses" do
    field :is_complete, :boolean
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name, :is_editable, :is_complete]
  @all_fields @req_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
