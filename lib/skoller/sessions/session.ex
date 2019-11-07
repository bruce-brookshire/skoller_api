defmodule Skoller.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Sessions.SessionPlatform
  alias Skoller.Sessions.Session
  alias Skoller.Users.User

  schema "sessions" do
    field :user_id, :id
    field :session_platform_id, :id

    belongs_to :user, User, define_field: false
    belongs_to :session_platform, SessionPlatform, define_field: false

    timestamps()
  end

  @req_fields [:user_id, :session_platform_id]
  @all_fields @req_fields

  def insert_changeset(params) do
    %Session{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
