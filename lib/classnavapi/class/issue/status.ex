defmodule Classnavapi.Class.Issue.Status do

  @moduledoc """
  
  Defines schema and changeset for class issue statuses.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Issue.Status

  @primary_key {:id, :id, []}
  schema "class_issue_statuses" do
    field :notes, :string
    field :status, :string

    timestamps()
  end

  @req_fields [:id, :status]
  @opt_fields [:notes]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
