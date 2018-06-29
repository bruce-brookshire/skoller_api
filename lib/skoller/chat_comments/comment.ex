defmodule Skoller.ChatComments.Comment do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.ChatComments.Comment
  alias Skoller.Students.Student
  alias Skoller.ChatReplies.Reply
  alias Skoller.ChatComments.Like
  alias Skoller.ChatPosts.Post

  schema "chat_comments" do
    field :comment, :string
    field :student_id, :id
    field :chat_post_id, :id
    has_many :chat_replies, Reply, foreign_key: :chat_comment_id
    belongs_to :student, Student, define_field: false
    has_many :likes, Like, foreign_key: :chat_comment_id
    belongs_to :chat_post, Post, define_field: false

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
