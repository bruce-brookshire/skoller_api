defmodule Skoller.Repo.Migrations.StudentTodoPreferences do
  use Ecto.Migration

  def up do
    alter table(:students) do
      add(:todo_days_future, :integer, default: 10)
      add(:todo_days_past, :integer, default: 2)
    end

    flush()
    
  end

  def down do
    alter table(:students) do
      remove(:todo_days_future)
      remove(:todo_days_past)
    end
  end
end
