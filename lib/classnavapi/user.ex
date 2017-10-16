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

  @all_fields [:email, :password]
  @req_fields [:email, :password]
  @upd_fields [:password]

  @doc false
  def changeset_insert(%User{} = user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:email)
    |> cast_assoc(:student)
    |> validate_email(attrs["student"])
  end

  def changeset_update(%User{} = user, attrs) do
    user
    |> cast(attrs, @upd_fields)
    |> validate_required([:email, :password])
    |> cast_assoc(:student)
  end
end
