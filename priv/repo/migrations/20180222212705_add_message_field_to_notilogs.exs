defmodule Skoller.Repo.Migrations.AddMessageFieldToNotilogs do
  use Ecto.Migration

  def change do
    alter table(:manual_notification_logs) do
      add :msg, :string, size: 750
    end
  end
end
