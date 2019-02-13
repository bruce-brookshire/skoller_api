defmodule Skoller.Repo.Migrations.AddClassStartToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :is_class_start_enabled, :bool, default: true, null: false
    end
  end
end
