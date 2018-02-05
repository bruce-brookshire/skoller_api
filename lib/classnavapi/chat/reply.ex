defmodule Classnavapi.Chat.Reply do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Reply


  schema "chat_replies" do
    field :reply, :string
    field :student_id, :id
    field :chat_comment_id, :id
    belongs_to :student, Classnavapi.Student, define_field: false

    timestamps()
  end

  @req_fields [:reply, :student_id, :chat_comment_id]
  @all_fields @req_fields

  @upd_req [:reply]
  @upd_fields @upd_req

  @doc false
  def changeset(%Reply{} = reply, attrs) do
    reply
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_comment_id)
  end

  def changeset_update(%Reply{} = reply, attrs) do
    reply
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
  end
end
