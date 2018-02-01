defmodule Classnavapi.Chat.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Chat.Post


  schema "chat_posts" do
    field :post, :string
    field :student_id, :id
    field :class_id, :id

    timestamps()
  end

  @req_fields [:post, :student_id, :class_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
