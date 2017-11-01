defmodule Classnavapi.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string
      add :adr_line_1, :string
      add :adr_line_2, :string
      add :adr_city, :string
      add :adr_state, :string
      add :adr_zip, :string
      add :timezone, :string
      add :is_active_enrollment, :boolean, default: true, null: false
      add :is_readonly, :boolean, default: false, null: false
      add :is_diy_enabled, :boolean, default: true, null: false
      add :is_diy_preferred, :boolean, default: false, null: false
      add :is_auto_syllabus, :boolean, default: true, null: false

      timestamps()
    end

    alter table(:students) do
      add :school_id, references(:schools)
    end

    create index(:students, [:school_id])
  end
end
