defmodule Skoller.Repo.Migrations.UpdateConstraintsOnMods do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop constraint("assignment_modifications", "assignment_modifications_student_id_fkey")
    alter table(:assignment_modifications) do
      modify :student_id, references(:students, on_delete: :nilify_all)
    end
  end
end
