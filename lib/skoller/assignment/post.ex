defmodule Skoller.Assignment.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Assignment.Post


  schema "assignment_posts" do
    field :post, :string
    field :assignment_id, :id
    field :student_id, :id
    belongs_to :student, Skoller.Student, define_field: false
    belongs_to :assignment, Skoller.Class.Assignment, define_field: false

    timestamps()
  end

  @req_fields [:post, :assignment_id, :student_id]
  @all_fields @req_fields

  @upd_req [:post]
  @upd_fields @upd_req

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def changeset_update(%Post{} = post, attrs) do
    post
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
  end
end
