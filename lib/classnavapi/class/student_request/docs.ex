defmodule Classnavapi.Class.StudentRequest.Docs do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest.Docs


  schema "class_student_request_docs" do
    field :class_student_request_id, :id
    field :doc_id, :id

    timestamps()
  end

  @doc false
  def changeset(%Docs{} = docs, attrs) do
    docs
    |> cast(attrs, [])
    |> validate_required([])
  end
end
