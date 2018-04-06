defmodule Classnavapi.Class.StudentRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest
  alias Classnavapi.Users.User
  alias Classnavapi.Class.StudentRequest.Type
  alias Classnavapi.Class.StudentRequest.Doc
  alias Classnavapi.Universities.Class

  schema "class_student_requests" do
    field :is_completed, :boolean, default: false
    field :notes, :string
    field :class_student_request_type_id, :id
    field :class_id, :id
    field :user_id, :id
    belongs_to :class, Class, define_field: false
    belongs_to :class_student_request_type, Type, define_field: false
    has_many :class_student_request_docs, Doc, foreign_key: :class_student_request_id
    has_many :request_docs, through: [:class_student_request_docs, :docs]
    belongs_to :user, User, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_student_request_type_id]
  @opt_fields [:notes, :is_completed, :user_id]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%StudentRequest{} = student_request, attrs) do
    student_request
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
