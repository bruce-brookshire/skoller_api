defmodule Classnavapi.Repo.Migrations.ChangeIsNotificationsOnSa do
  use Ecto.Migration

  def change do
    rename table("student_assignments"), :is_notifications, to: :is_reminder_notifications
    alter table(:student_assignments) do
      add :is_post_notifications, :boolean, default: true, null: false
    end
  end
end
