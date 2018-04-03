defmodule Classnavapi.Repo.Migrations.AddMoreNotificaitonTimes do
  use Ecto.Migration

  alias Classnavapi.Repo

  def up do
    alter table(:students) do
      add :future_reminder_notification_time, :time
    end
    flush()
    Classnavapi.Student
    |> Repo.all()
    |> Enum.map(&Ecto.Changeset.change(&1, %{future_reminder_notification_time: &1.notification_time}))
    |> Enum.each(&Repo.update!(&1))
  end

  def down do
    alter table(:students) do
      remove :future_reminder_notification_time
    end
  end
end
