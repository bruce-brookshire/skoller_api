defmodule Skoller.Users.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.Role
  alias Skoller.UserReports.Report
  alias Skoller.Services.Authentication

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :pic_path, :string
    field :is_active, :boolean, default: true
    field :is_unsubscribed, :boolean, default: false
    belongs_to :student, Student
    many_to_many :roles, Role, join_through: "user_roles"
    has_many :reports, Report

    timestamps()
  end

  @req_fields [:email, :password]
  @opt_fields [:pic_path]
  @all_fields @req_fields ++ @opt_fields
  @upd_req [:is_unsubscribed]
  @upd_opt [:password, :pic_path]
  @upd_fields @upd_req ++ @upd_opt
  @adm_upd_req [:is_active, :is_unsubscribed]
  @adm_upd_opt [:password, :pic_path]
  @adm_upd_fields @adm_upd_req ++ @adm_upd_opt

  @doc false
  def changeset_insert(%User{} = user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> update_change(:email, &String.downcase(&1))
    |> update_change(:email, &String.trim(&1))
    |> unique_constraint(:email)
    |> cast_assoc(:student)
    |> validate_format(:email, ~r/@/)
    |> put_pass_hash()
  end

  @doc false
  def changeset_update(%User{} = user, attrs) do
    user
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
    |> cast_assoc(:student)
    |> put_pass_hash()
  end

  @doc false
  def changeset_update_admin(%User{} = user, attrs) do
    user
    |> cast(attrs, @adm_upd_fields)
    |> validate_required(@adm_upd_req)
    |> cast_assoc(:student)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes:
                      %{password: password}} = changeset) do
    change(changeset, Authentication.hash_password(password))
  end
  defp put_pass_hash(changeset), do: changeset
end
