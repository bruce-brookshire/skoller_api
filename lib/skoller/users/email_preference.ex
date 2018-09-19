defmodule Skoller.Users.EmailPreference do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Users.EmailPreference

  schema "user_email_preferences" do
    field :is_unsubscribed, :boolean, default: false
    field :user_id, :id
    field :email_type_id, :id

    timestamps()
  end

  @req_fields [:is_unsubscribed, :email_type_id, :user_id]
  @all_fields @req_fields

  @doc false
  def changeset(%EmailPreference{} = email_preference, attrs) do
    email_preference
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:user_id, name: :user_email_preferences_unique_index)
  end
end
