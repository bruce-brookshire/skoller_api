defmodule Classnavapi.Assignments.ReminderNotification do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignments.ReminderNotification


  schema "assignment_reminder_notifications" do
    field :message, :string
    field :topic, :string
    field :is_plural, :boolean, default: true

    timestamps()
  end

  @req_fields [:topic, :message, :is_plural]
  @all_fields @req_fields

  @doc false
  def changeset(%ReminderNotification{} = reminder_notification, attrs) do
    reminder_notification
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_length(:message, max: 150)
  end
end
