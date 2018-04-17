defmodule Skoller.Repo.Migrations.AddIsUniversityBoolToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :is_university, :boolean, default: true, null: false
    end
  end
end
