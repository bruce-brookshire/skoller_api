defmodule Skoller.Chat.Comment.Star do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Chat.Comment.Star


  schema "chat_comment_stars" do
    field :chat_comment_id, :id
    field :student_id, :id
    field :is_read, :boolean, default: false
    belongs_to :chat_comment, Skoller.Chat.Comment, define_field: false

    timestamps()
  end

  @req_fields [:chat_comment_id, :student_id, :is_read]
  @all_fields @req_fields

  @doc false
  def changeset(%Star{} = star, attrs) do
    star
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_comment_id)
    |> unique_constraint(:star, name: :unique_comment_star_index)
  end
end
