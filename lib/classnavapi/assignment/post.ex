defmodule Classnavapi.Assignment.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignment.Post


  schema "assignment_posts" do
    field :post, :string
    field :assignment_id, :id
    field :student_id, :id
    belongs_to :student, Classnavapi.Student, define_field: false
    belongs_to :assignment, Classnavapi.Class.Assignment, define_field: false

    timestamps()
  end

  @req_fields [:post, :assignment_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
