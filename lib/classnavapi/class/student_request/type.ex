defmodule Classnavapi.Class.StudentRequest.Type do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest.Type

  @primary_key {:id, :id, []}
  schema "class_student_request_types" do
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name]
  @all_fields @req_fields

  @doc false
  def changeset(%Type{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
