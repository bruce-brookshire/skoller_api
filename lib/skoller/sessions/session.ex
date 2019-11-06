defmodule Skoller.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Sessions.SessionPlatform
  alias Skoller.Students.Student
  alias Skoller.Sessions.Session

  schema "sessions" do
    field :student_id, :id
    field :session_platform_id, :id

    belongs_to :student, Student, define_field: false
    belongs_to :session_platform, SessionPlatform, define_field: false

    timestamps()
  end

  @req_fields [:student_id, :session_platform_id]
  @all_fields @req_fields

  def insert_changeset(params) do
    %Session{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
