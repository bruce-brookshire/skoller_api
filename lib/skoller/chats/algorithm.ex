defmodule Skoller.Chats.Algorithm do
  @moduledoc false
  
  use Ecto.Schema
  
  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "chat_algorithms" do
    field :name, :string

    timestamps()
  end
end
