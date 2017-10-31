defmodule Classnavapi.User do

  @moduledoc """
  
  Defines changeset and schema for users.
  
  Email will be validated against school email domains if the user is a student.

  """

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

  defp extract_domain(changeset) do
    changeset
    |> get_field(:email)
    |> String.split("@")
    |> Enum.take(-1)
    |> List.first()
  end

  def validate_email(changeset, nil), do: changeset
  def validate_email(changeset, student_obj) do
    school = Repo.get(Classnavapi.School, student_obj["school_id"])
    if school == nil do
      add_error(changeset, :student, "Invalid school")
    else
      school = Repo.preload school, :email_domains
      email_domains = school.email_domains
      user_email_domain = "@" <> extract_domain(changeset)
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
