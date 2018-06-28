defmodule Skoller.Assignments.ReminderNotification do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Assignments.ReminderNotification

  schema "assignment_reminder_notifications" do
    field :message, :string
    field :assignment_reminder_notification_topic_id, :id
    field :is_plural, :boolean, default: true
    belongs_to :assignment_reminder_notification_topic, Skoller.Assignments.ReminderNotification.Topic, define_field: false

    timestamps()
  end

  @req_fields [:assignment_reminder_notification_topic_id, :message, :is_plural]
  @all_fields @req_fields

  @doc false
  def changeset(%ReminderNotification{} = reminder_notification, attrs) do
    reminder_notification
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_length(:message, max: 150)
  end
end
