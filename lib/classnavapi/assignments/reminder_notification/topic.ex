defmodule Classnavapi.Assignments.ReminderNotification.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignments.ReminderNotification.Topic

  @all_fields [:topic]

  schema "assignment_reminder_notification_topics" do
    field :topic, :string

    timestamps()
  end

  @doc false
  def changeset(%Topic{} = topic, attrs) do
    topic
    |> cast(attrs, @all_field)
    |> validate_required(@all_field)
  end
end
