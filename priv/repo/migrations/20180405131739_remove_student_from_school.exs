defmodule Skoller.Repo.Migrations.RemoveStudentFromSchool do
  use Ecto.Migration

  def change do
    drop constraint("students", "students_school_id_fkey")
    alter table(:students) do
      remove :school_id
    end

    alter table(:schools) do
      remove :is_active_enrollment
    end
  end
end
