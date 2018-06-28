defmodule Skoller.Repo.Migrations.RemoveClassDates do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      remove :class_start
      remove :class_end
    end
  end

  def down do
    alter table(:classes) do
      add :class_start, :date
      add :class_end, :date
    end
  end
end
