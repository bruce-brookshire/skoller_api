defmodule Skoller.Repo.Migrations.CascadeDeleteAssignments do
  use Ecto.Migration

  def change do
    drop constraint("student_assignments", "student_assignments_assignment_id_fkey")
    alter table(:student_assignments) do
      modify :assignment_id, references(:assignments, on_delete: :delete_all)
    end

    drop constraint("assignment_modifications", "assignment_modifications_assignment_id_fkey")
    alter table(:assignment_modifications) do
      modify :assignment_id, references(:assignments, on_delete: :delete_all)
    end

    drop constraint("modification_actions", "modification_actions_assignment_modification_id_fkey")
    alter table(:modification_actions) do
      modify :assignment_modification_id, references(:assignment_modifications, on_delete: :delete_all)
    end
  end
end
