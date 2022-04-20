defmodule Skoller.Payments.Stripe do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Users.User

  schema "customers_info" do
    field :customer_id, :string
    field :payment_method, :string
    field :billing_details, :map
    field :card_info, :map
    belongs_to :user, Skoller.Users.User
    timestamps()
  end

  @doc false
  def changeset(stripe, attrs) do
    stripe
    |> cast(attrs, [:user_id, :customer_id, :payment_method, :card_info, :billing_details])
    |> validate_required([:user_id, :customer_id])
  end
end
