defmodule Skoller.Repo.Migrations.AddMoreNotificaitonTimes do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:students) do
      add :future_reminder_notification_time, :time
    end
  end

  def down do
    alter table(:students) do
      remove :future_reminder_notification_time
    end
  end
end
