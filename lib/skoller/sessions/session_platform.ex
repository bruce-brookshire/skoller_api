defmodule Skoller.Sessions.SessionPlatform do
  
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Skoller.Sessions.SessionPlatform

  schema "session_platforms" do
    field :type, :string
  end

  @req_fields [:id, :type]
  @all_fields @req_fields

  def insert_changeset(%{} = params) do
    %SessionPlatform{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
