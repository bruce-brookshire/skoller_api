defmodule Skoller.Repo.Migrations.RemoveIsNewClass do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      remove :is_new_class
    end
  end

  def down do
    alter table(:classes) do
      add :is_new_class, :boolean, default: false, null: false
    end
  end
end
