defmodule Classnavapi.Notification.ManualLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Notification.ManualLog


  schema "manual_notification_logs" do
    field :affected_users, :string
    field :notification_category, :integer

    timestamps()
  end

  @doc false
  def changeset(%ManualLog{} = manual_log, attrs) do
    manual_log
    |> cast(attrs, [:notification_category, :affected_users])
    |> validate_required([:notification_category, :affected_users])
  end
end
