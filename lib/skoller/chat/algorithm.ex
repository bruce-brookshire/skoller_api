defmodule Skoller.Chat.Algorithm do
  use Ecto.Schema

  @primary_key {:id, :id, []}
  schema "chat_algorithms" do
    field :name, :string

    timestamps()
  end
end
