defmodule Classnavapi.Class.Issue do

  @moduledoc """
  
  Defines the schema and changeset for class_issues

  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Issue

  schema "class_issues" do
    field :note, :string
    field :is_completed, :boolean, default: false
    field :class_id, :id
    field :class_issue_status_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :class_issue_status, Classnavapi.Class.Issue.Status, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_issue_status_id]
  @opt_fields [:note]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Issue{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:class_issues, name: :class_issues_class_id_class_issues_status_id_index)
  end
end
