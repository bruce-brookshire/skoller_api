defmodule Skoller.EmailLog do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_logs" do
    field :email_type_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(email_log, attrs) do
    email_log
    |> cast(attrs, [])
    |> validate_required([])
  end
end
