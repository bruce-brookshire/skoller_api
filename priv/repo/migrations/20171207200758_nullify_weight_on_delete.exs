defmodule Classnavapi.Repo.Migrations.NullifyWeightOnDelete do
  use Ecto.Migration

  def change do
    drop constraint("assignments", "assignments_weight_id_fkey")
    alter table(:assignments) do
      modify :weight_id, references(:class_weights, on_delete: :nilify_all)
    end

    drop constraint("student_assignments", "student_assignments_weight_id_fkey")
    alter table(:student_assignments) do
      modify :weight_id, references(:class_weights, on_delete: :nilify_all)
    end
  end
end
