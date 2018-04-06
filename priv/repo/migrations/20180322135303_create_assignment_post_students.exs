defmodule Skoller.Repo.Migrations.CreateAssignmentPostStudents do
  use Ecto.Migration

  def change do
    alter table(:student_assignments) do
      add :is_read, :boolean, default: true, null: false
    end
  end
end
