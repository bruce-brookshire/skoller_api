defmodule Classnavapi.Repo.Migrations.RemoveStudentFromSchool do
  use Ecto.Migration

  def change do
    drop constraint("students", "students_school_id_fkey")
    alter table(:students) do
      remove :school_id
    end
  end
end
