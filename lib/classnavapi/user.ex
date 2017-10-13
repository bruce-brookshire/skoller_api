defmodule Classnavapi.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Classnavapi.User
  alias Classnavapi.Repo


  schema "users" do
    field :email, :string
    field :password, :string
    belongs_to :student, Classnavapi.Student

    timestamps()
  end

  def validate_email(changeset, nil), do: changeset
  def validate_email(changeset, student_obj) do
    school = Repo.get(Classnavapi.School, student_obj["school_id"])
    if (school == nil) do
      add_error(changeset, :student, "Invalid school")
    else
      email_domain = school.email_domain
      user_email = get_field(changeset, :email)
      if tl(String.split(email_domain, "@")) != tl(String.split(user_email, "@")) do
        add_error(changeset, :student, "Invalid email for school.")
      else
        changeset
      end
    end
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> unique_constraint(:email)
    |> cast_assoc(:student)
    |> validate_email(attrs["student"])
  end
end
