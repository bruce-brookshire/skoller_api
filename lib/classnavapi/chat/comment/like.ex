defmodule Classnavapi.Chat.Comment.Like do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Comment.Like


  schema "chat_comment_likes" do
    field :chat_comment_id, :id
    field :student_id, :id
    belongs_to :chat_comment, Classnavapi.Chat.Comment, define_field: false

    timestamps()
  end

  @req_fields [:chat_comment_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Like{} = like, attrs) do
    like
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_comment_id)
  end
end
