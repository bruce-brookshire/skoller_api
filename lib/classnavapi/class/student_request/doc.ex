defmodule Classnavapi.Class.StudentRequest.Doc do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest.Doc


  schema "class_student_request_docs" do
    field :class_student_request_id, :id
    field :doc_id, :id
    belongs_to :docs, Classnavapi.Class.Doc, define_field: false
    belongs_to :student_requests, Classnavapi.Class.StudentRequest, define_field: false

    timestamps()
  end

  @doc false
  def changeset(%Doc{} = docs, attrs) do
    docs
    |> cast(attrs, [])
    |> validate_required([])
  end
end
