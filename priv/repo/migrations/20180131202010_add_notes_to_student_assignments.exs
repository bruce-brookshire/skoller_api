defmodule Classnavapi.Repo.Migrations.AddNotesToStudentAssignments do
  use Ecto.Migration

  def change do
    alter table(:student_assignments) do
      add :notes, :string, size: 2000
    end
  end
end
