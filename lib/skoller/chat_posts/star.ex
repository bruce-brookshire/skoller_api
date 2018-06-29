defmodule Skoller.ChatPosts.Star do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.ChatPosts.Star

  schema "chat_post_stars" do
    field :chat_post_id, :id
    field :student_id, :id
    field :is_read, :boolean, default: false
    belongs_to :chat_post, Skoller.ChatPosts.Post, define_field: false

    timestamps()
  end

  @req_fields [:chat_post_id, :student_id, :is_read]
  @all_fields @req_fields

  @doc false
  def changeset(%Star{} = star, attrs) do
    star
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:chat_post_id)
    |> unique_constraint(:star, name: :unique_post_star_index)
  end
end
