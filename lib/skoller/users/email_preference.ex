defmodule Skoller.Users.EmailPreference do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Users.EmailPreference

  schema "user_email_preferences" do
    field :is_class_setup_email, :boolean, default: false
    field :is_no_classes_email, :boolean, default: false
    field :is_unsubscribed, :boolean, default: false
    field :user_id, :id

    timestamps()
  end

  @req_fields [:is_unsubscribed, :is_no_classes_email, :is_class_setup_email, :user_id]
  @all_fields @req_fields

  @doc false
  def changeset(%EmailPreference{} = email_preference, attrs) do
    email_preference
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
