defmodule Classnavapi.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Classnavapi.User

  schema "users" do
    field :email, :string
    field :password, :string
    belongs_to :student, Classnavapi.Student

    timestamps()
  end

  def student_assoc(changeset, nil), do: changeset
  def student_assoc(changeset, student_obj) do
    if student_obj["id"] == nil do
      Ecto.Changeset.cast_assoc(changeset, :student)
    else
      student_assoc = Classnavapi.Repo.get(Classnavapi.Student, student_obj["id"])
      if student_assoc != nil do
        Ecto.Changeset.put_assoc(changeset, :student, student_assoc)
      else
        Ecto.Changeset.cast_assoc(changeset, :student)
      end
    end
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> student_assoc(attrs["student"])
  end
end
