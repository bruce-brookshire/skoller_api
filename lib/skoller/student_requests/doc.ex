defmodule Skoller.StudentRequests.Doc do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.StudentRequests.Doc

  schema "class_student_request_docs" do
    field :class_student_request_id, :id
    field :doc_id, :id
    belongs_to :docs, Skoller.Class.Doc, define_field: false
    belongs_to :class_student_requests, Skoller.StudentRequests.StudentRequest, define_field: false

    timestamps()
  end

  @doc false
  def changeset(%Doc{} = docs, attrs) do
    docs
    |> cast(attrs, [])
    |> validate_required([])
  end
end
