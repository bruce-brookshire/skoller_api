defmodule Classnavapi.Repo.Migrations.NotificationToggles do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :notification_time, :time
      add :notification_days_notice, :int
      add :is_notifications, :boolean, default: true, null: false
    end

    alter table(:student_classes) do
      add :is_notifications, :boolean, default: true, null: false
    end

    alter table(:student_assignments) do
      add :is_notifications, :boolean, default: true, null: false
    end
  end
end
