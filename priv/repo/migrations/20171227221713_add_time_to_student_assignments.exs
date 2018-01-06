defmodule Classnavapi.Repo.Migrations.AddTimeToStudentAssignments do
  use Ecto.Migration

  def up do

    alter table(:student_assignments) do
      modify :due, :utc_datetime
    end


  end

  def down do
    alter table(:student_assignments) do
      modify :due, :date
    end

  end
end
