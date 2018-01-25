defmodule Classnavapi.Class.StudentRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest

  schema "class_student_requests" do
    field :is_completed, :boolean, default: false
    field :notes, :string
    field :class_student_request_type_id, :id
    field :class_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :class_student_request_type, Classnavapi.Class.StudentRequest.Type, define_field: false
    has_many :student_request_docs,  Classnavapi.Class.StudentRequest.Doc
    has_many :request_docs, through: [:student_request_docs, :docs]

    timestamps()
  end

  @req_fields [:class_id, :class_student_request_type_id]
  @opt_fields [:notes, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%StudentRequest{} = student_request, attrs) do
    student_request
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
