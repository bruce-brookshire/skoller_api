defmodule Skoller.EmailJobs.EmailJob do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.EmailTypes.EmailType

  schema "email_jobs" do
    field :user_id, :id
    field :email_type_id, :id
    field :is_running, :boolean
    field :options, :map

    belongs_to :user, User, define_field: false
    belongs_to :email_type, EmailType, define_field: false

    timestamps()
  end


  @opt_attr [:is_running, :options]
  @req_attr [:user_id, :email_type_id]
  @all_attr @opt_attr ++ @req_attr

  @doc false
  def changeset(email_log, attrs) do
    email_log
    |> cast(attrs, @all_attr)
    |> validate_required(@req_attr)
  end
end
