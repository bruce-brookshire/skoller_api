defmodule Skoller.Repo.Migrations.RemoveClassStartSchool do
  use Ecto.Migration

  def up do
    alter table(:schools) do
      remove :is_class_start_enabled
    end
    alter table(:email_types) do
      modify :is_active_email, :bool, default: nil
      modify :is_active_notification, :bool, default: nil
    end
  end

  def down do
    alter table(:schools) do
      add :is_class_start_enabled, :bool, default: true
    end
    alter table(:email_types) do
      modify :is_active_email, :bool, default: true
      modify :is_active_notification, :bool, default: true
    end
  end
end
