defmodule Skoller.Users.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.Roles.Role
  alias Skoller.UserReports.Report
  alias Skoller.Services.Authentication
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.Organizations.OrgOwners.OrgOwner
  alias Skoller.Organizations.OrgMembers.OrgMember
  alias Skoller.CancellationReasons.CancellationReason

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :pic_path, :string
    field :is_active, :boolean, default: true
    field :is_unsubscribed, :boolean, default: false
    field :last_login, :utc_datetime
    field :trial_start, :utc_datetime
    field :trial_end, :utc_datetime
    field :trial, :boolean, default: true
    field :lifetime_subscription, :boolean, default: false
    field :lifetime_trial, :boolean, default: false

    belongs_to :student, Student

    many_to_many :roles, Role, join_through: "user_roles"

    has_many :reports, Report

    has_one :job_profile, JobProfile

    has_many :org_owners, OrgOwner
    has_many :org_members, OrgMember
    has_many :org_group_owners, through: [:org_members, :org_group_owners]
    has_many :cancellation_reasons, CancellationReason, on_delete: :nilify_all

    has_one :customer_info, Skoller.Payments.Stripe, on_delete: :delete_all

    timestamps()
  end

  @req_fields []
  @opt_fields [:pic_path, :password]
  @all_fields @req_fields ++ @opt_fields
  @upd_req [:is_unsubscribed]
  @upd_opt [:password, :pic_path, :last_login]
  @upd_fields @upd_req ++ @upd_opt
  @adm_upd_req [:is_active, :is_unsubscribed, :email]
  @adm_upd_opt [:password, :pic_path, :last_login]
  @adm_upd_fields @adm_upd_req ++ @adm_upd_opt

  @doc false
  def changeset_insert(%User{} = user, attrs) do
    user
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> change(%{trial_start: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> change(%{
      trial_end:
        DateTime.utc_now() |> DateTime.add(60 * 60 * 24 * 7) |> DateTime.truncate(:second)
    })
    |> cast_assoc(:student)
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

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Authentication.hash_password(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
