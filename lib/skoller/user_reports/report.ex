defmodule Skoller.UserReports.Report do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Users.User
  alias Skoller.UserReports.Report

  schema "user_reports" do
    field :context, :string
    field :note, :string
    field :user_id, :id
    field :is_complete, :boolean, default: false
    field :reported_by, :id
    belongs_to :reporter, User, define_field: false, foreign_key: :reported_by
    belongs_to :user, User, define_field: false

    timestamps()
  end

  @req_fields [:user_id, :context, :reported_by]
  @opt_fields [:note]
  @all_fields @req_fields ++ @opt_fields

  @upd_req [:is_complete]
  @upd_all @upd_req

  @doc false
  def changeset(%Report{} = report, attrs) do
    report
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reported_by)
  end

  def changeset_update(%Report{} = report, attrs) do
    report
    |> cast(attrs, @upd_all)
    |> validate_required(@upd_req)
  end
end
