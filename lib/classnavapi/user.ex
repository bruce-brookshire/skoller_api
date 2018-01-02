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
    field :password, :string, virtual: true
    field :password_hash, :string
    field :pic_path, :string
    field :is_active, :boolean, default: true
    belongs_to :student, Classnavapi.Student
    many_to_many :roles, Classnavapi.Role, join_through: "user_roles"
    timestamps()
  end

  @req_fields [:email, :password]
  @opt_fields [:pic_path]
  @all_fields @req_fields ++ @opt_fields
  @upd_req []
  @upd_opt [:password, :pic_path]
  @upd_fields @upd_req ++ @upd_opt
  @adm_upd_req [:is_active]
  @adm_upd_opt [:password, :pic_path]
  @adm_upd_fields @adm_upd_req ++ @adm_upd_opt

  @doc false
  def changeset_insert(%User{} = user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> update_change(:email, &String.downcase(&1))
    |> unique_constraint(:email)
    |> cast_assoc(:student)
    |> validate_format(:email, ~r/@/)
    |> validate_email(attrs["student"])
    |> put_pass_hash()
  end

  def changeset_update(%User{} = user, attrs) do
    user
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
    |> cast_assoc(:student)
    |> put_pass_hash()
  end

  def changeset_update_admin(%User{} = user, attrs) do
    user
    |> cast(attrs, @adm_upd_fields)
    |> validate_required(@adm_upd_req)
    |> cast_assoc(:student)
    |> put_pass_hash()
  end

  defp extract_domain(changeset) do
    changeset
    |> get_field(:email)
    |> String.split("@")
    |> Enum.take(-1)
    |> List.first()
  end

  defp preload_school(nil), do: nil
  defp preload_school(school) do
    Repo.preload school, :email_domains
  end

  defp validate_match(changeset, nil), do: changeset |> add_error(:student, "Invalid email for school.")
  defp validate_match(changeset, _), do: changeset

  defp compare_domains(changeset, nil), do: changeset |> add_error(:student, "Invalid school")
  defp compare_domains(changeset, school) do
    email_domains = school.email_domains

    match = email_domains
    |> Enum.find(& &1.email_domain == "@" <> extract_domain(changeset))

    changeset
    |> validate_match(match)
  end

  defp validate_email(changeset, nil), do: changeset
  defp validate_email(changeset, student_obj) do
    school = Repo.get(Classnavapi.School, student_obj["school_id"])

    school = school |> preload_school

    changeset
    |> compare_domains(school)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes:
                      %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end
  defp put_pass_hash(changeset), do: changeset
end
