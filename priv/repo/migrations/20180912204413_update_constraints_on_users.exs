defmodule Skoller.Repo.Migrations.UpdateConstraintsOnUsers do
  use Ecto.Migration

  def up do
    drop constraint("users", "users_student_id_fkey")
    drop constraint("user_roles", "user_roles_user_id_fkey")
    drop constraint("student_classes", "student_classes_student_id_fkey")
    drop constraint("student_assignments", "student_assignments_student_class_id_fkey")
    drop constraint("class_locks", "class_locks_user_id_fkey")
    drop constraint("class_abandoned_locks", "class_abandoned_locks_user_id_fkey")
    alter table(:class_abandoned_locks) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
    alter table(:class_locks) do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end
    alter table(:student_assignments) do
      modify :student_class_id, references(:student_classes, on_delete: :delete_all)
    end
    alter table(:student_classes) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:users) do
      modify :student_id, references(:students, on_delete: :nilify_all)
    end
    alter table(:user_roles) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
  end

  def down do
    drop constraint("users", "users_student_id_fkey")
    drop constraint("user_roles", "user_roles_user_id_fkey")
    drop constraint("student_classes", "student_classes_student_id_fkey")
    drop constraint("student_assignments", "student_assignments_student_class_id_fkey")
    drop constraint("class_locks", "class_locks_user_id_fkey")
    drop constraint("class_abandoned_locks", "class_abandoned_locks_user_id_fkey")
    alter table(:class_abandoned_locks) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    alter table(:class_locks) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    alter table(:student_assignments) do
      modify :student_class_id, references(:student_classes, on_delete: :nothing)
    end
    alter table(:student_classes) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:users) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:user_roles) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
  end
end
