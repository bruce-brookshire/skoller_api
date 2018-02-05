defmodule Classnavapi.Chat.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Post


  schema "chat_posts" do
    field :post, :string
    field :student_id, :id
    field :class_id, :id
    has_many :chat_comments, Classnavapi.Chat.Comment, foreign_key: :chat_post_id
    belongs_to :student, Classnavapi.Student, define_field: false

    timestamps()
  end

  @req_fields [:post, :student_id, :class_id]
  @all_fields @req_fields

  @upd_req [:post]
  @upd_fields @upd_req

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def update_changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
  end
end
