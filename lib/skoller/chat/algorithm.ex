defmodule Skoller.Chat.Algorithm do
  @moduledoc false
  
  use Ecto.Schema

  @primary_key {:id, :id, []}
  schema "chat_algorithms" do
    field :name, :string

    timestamps()
  end
end
