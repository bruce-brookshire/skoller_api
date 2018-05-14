defmodule Skoller.Repo.Migrations.ResetFieldsOfStudy do
  use Ecto.Migration

  def change do
    drop table(:student_fields_of_study)
    drop table(:fields_of_study)
    flush()
    create table(:fields_of_study) do
      add :field, :string

      timestamps()
    end

    create unique_index(:fields_of_study, [:field])
    flush()
    
    create table(:student_fields_of_study) do
      add :field_of_study_id, references(:fields_of_study, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:student_fields_of_study, [:field_of_study_id])
    create index(:student_fields_of_study, [:student_id])
    create unique_index(:student_fields_of_study, [:field_of_study_id, :student_id])
  end
end
