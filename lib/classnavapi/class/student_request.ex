defmodule Classnavapi.Class.StudentRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.StudentRequest


  schema "class_student_requests" do
    field :is_completed, :boolean, default: false
    field :notes, :string
    field :class_student_request_type_id, :id
    field :class_id, :id

    timestamps()
  end

  @doc false
  def changeset(%StudentRequest{} = student_request, attrs) do
    student_request
    |> cast(attrs, [:notes, :is_completed])
    |> validate_required([:notes, :is_completed])
  end
end
