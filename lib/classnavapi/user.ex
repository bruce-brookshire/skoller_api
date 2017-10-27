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
    if school == nil do
      add_error(changeset, :student, "Invalid school")
    else
      school = Repo.preload school, :email_domains
      email_domains = school.email_domains
      user_email_domain = "@" <> List.first(Enum.take(String.split(get_field(changeset, :email), "@"), -1))
      if Enum.find(email_domains, fn(x) -> x.email_domain == user_email_domain end) == nil do
        add_error(changeset, :student, "Invalid email for school.")
      else
        changeset
      end
    end
  end

  @req_fields [:email, :password]
  @all_fields @req_fields
  @upd_fields [:password]

  @doc false
  def changeset_insert(%User{} = user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:email)
    |> cast_assoc(:student)
    |> validate_format(:email, ~r/@/)
    |> validate_email(attrs["student"])
  end

  def changeset_update(%User{} = user, attrs) do
    user
    |> cast(attrs, @upd_fields)
    |> validate_required([:email, :password])
    |> cast_assoc(:student)
  end
end
