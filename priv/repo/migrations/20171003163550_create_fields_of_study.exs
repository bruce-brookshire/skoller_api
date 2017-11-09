defmodule Classnavapi.Repo.Migrations.CreateFieldsOfStudy do
  use Ecto.Migration

  def change do
    create table(:fields_of_study) do
      add :field, :string
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:fields_of_study, [:school_id])
    create unique_index(:fields_of_study, [:field, :school_id])
  end
end
