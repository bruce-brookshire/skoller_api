defmodule Classnavapi.Student do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Student


  schema "students" do
    field :birthday, :date
    field :gender, :string
    field :name_first, :string
    field :name_last, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(%Student{} = student, attrs) do
    student
    |> cast(attrs, [:name_first, :name_last, :phone, :birthday, :gender])
    |> validate_required([:name_first, :name_last, :phone, :birthday, :gender])
  end
end
