defmodule Skoller.Repo.Migrations.UpdateEnrolledByName do
  use Ecto.Migration

  def change do
      rename table(:students), :enrolled_by, to: :enrolled_by_student_id
  end
end
