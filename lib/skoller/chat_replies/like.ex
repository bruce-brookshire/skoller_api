defmodule Skoller.ChatReplies.Like do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.ChatReplies.Like

  schema "chat_reply_likes" do
    field :chat_reply_id, :id
    field :student_id, :id
    belongs_to :chat_reply, Skoller.ChatReplies.Reply, define_field: false

    timestamps()
  end

  @req_fields [:chat_reply_id, :student_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Like{} = like, attrs) do
    like
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_reply_id)
    |> unique_constraint(:like, name: :unique_reply_like_index)
  end
end
