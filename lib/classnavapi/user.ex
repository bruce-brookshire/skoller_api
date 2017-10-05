defmodule Classnavapi.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.User


  schema "users" do
    field :birthday, :date
    field :email, :string
    field :gender, :string
    field :grad_year, :integer
    field :major, :string
    field :name_first, :string
    field :name_last, :string
    field :password, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :name_first, :name_last, :phone, :major, :grad_year, :birthday, :gender, :password])
    |> validate_required([:email, :name_first, :name_last, :phone, :major, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
