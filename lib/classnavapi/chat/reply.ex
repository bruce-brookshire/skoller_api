defmodule Classnavapi.Chat.Reply do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Reply


  schema "chat_replies" do
    field :reply, :string
    field :student_id, :id
    field :chat_comment_id, :id

    timestamps()
  end

  @req_fields [:reply, :student_id, :chat_comment_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Reply{} = reply, attrs) do
    reply
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
