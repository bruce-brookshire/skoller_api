defmodule Classnavapi.Repo.Migrations.AddColorToStudentClasses do
  use Ecto.Migration

  def change do
    alter table(:student_classes) do
      add :color, :string
    end
  end
end
