defmodule Classnavapi.Chat.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Comment


  schema "chat_comments" do
    field :comment, :string
    field :student_id, :id
    field :chat_post_id, :id
    has_many :chat_replies, Classnavapi.Chat.Reply, foreign_key: :chat_comment_id
    belongs_to :student, Classnavapi.Student, define_field: false
    has_many :likes, Classnavapi.Chat.Comment.Like, foreign_key: :chat_comment_id

    timestamps()
  end

  @req_fields [:comment, :student_id, :chat_post_id]
  @all_fields @req_fields

  @upd_req [:comment]
  @upd_fields @upd_req

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_post_id)
  end

  def changeset_update(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
  end
end
