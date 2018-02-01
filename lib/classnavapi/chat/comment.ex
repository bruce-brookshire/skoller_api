defmodule Classnavapi.Chat.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Comment


  schema "chat_comments" do
    field :comment, :string
    field :student_id, :id
    field :chat_post_id, :id

    timestamps()
  end

  @req_fields [:comment, :student_id, :chat_post_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
