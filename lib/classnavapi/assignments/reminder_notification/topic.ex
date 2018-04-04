defmodule Classnavapi.Assignments.ReminderNotification.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignments.ReminderNotification.Topic

  @all_fields [:id, :topic, :name]

  @primary_key {:id, :id, []}
  schema "assignment_reminder_notification_topics" do
    field :topic, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Topic{} = topic, attrs) do
    topic
    |> cast(attrs, @all_fields)
    |> validate_required(@all_fields)
  end
end
