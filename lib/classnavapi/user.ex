defmodule Classnavapi.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.User


  schema "users" do
    field :email, :string
    field :password, :string
    field :student_id, :id

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
