defmodule Classnavapi.Class.Doc do

  @moduledoc """
  
  The changeset and schema for docs.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Doc
  alias Classnavapi.Class

  schema "docs" do
    field :is_syllabus, :boolean, default: false
    field :path, :string
    field :class_id, :id
    belongs_to :class, Class, define_field: false

    timestamps()
  end

  @req_fields [:path, :is_syllabus, :class_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Doc{} = doc, attrs) do
    doc
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_id)
  end
end
