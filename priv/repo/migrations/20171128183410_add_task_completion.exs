defmodule Skoller.Repo.Migrations.AddTaskCompletion do
  use Ecto.Migration

  def change do
    alter table(:student_assignments) do
      add :is_completed, :boolean, default: false, null: false
    end
  end
end
