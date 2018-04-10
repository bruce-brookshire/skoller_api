defmodule Skoller.Repo.Migrations.AppNotificationToggles do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :is_mod_notifications, :boolean, default: true, null: false
      add :is_reminder_notifications, :boolean, default: true, null: false
      add :is_chat_notifications, :boolean, default: true, null: false
    end
  end
end
