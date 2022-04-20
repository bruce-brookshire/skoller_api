defmodule Skoller.CancellationReasons.CancellationReason do
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Users.User

  schema "cancellation_reasons" do
    field :description, :string
    field :title, Skoller.Enum.CancellationReasonTitle

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(cancellation_reason, attrs) do
    cancellation_reason
    |> cast(attrs, [:title, :description, :user_id])
    |> validate_required([:title, :user_id])
  end
end
