defmodule Classnavapi.Repo.Migrations.AddLockDiyFlag do
  use Ecto.Migration

  def change do
    alter table(:class_lock_sections) do
      add :is_diy, :boolean, default: true, null: false
    end
  end
end
