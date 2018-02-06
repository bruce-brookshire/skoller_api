defmodule Classnavapi.Chat.Post.Like do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Post.Like


  schema "chat_post_likes" do
    field :chat_post_id, :id
    field :student_id, :id

    timestamps()
  end

  @req_fields [:chat_post_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Like{} = like, attrs) do
    like
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_post_id)
    |> unique_constraint(:like, name: :unique_post_like_index)
  end
end
