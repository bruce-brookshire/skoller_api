defmodule Classnavapi.Repo.Migrations.MakeClassesDeleteCascade do
  use Ecto.Migration

  def change do
    drop constraint("student_classes", "student_classes_class_id_fkey")
    alter table(:student_classes) do
      modify :class_id, references(:classes, on_delete: :delete_all)
    end
  end
end
