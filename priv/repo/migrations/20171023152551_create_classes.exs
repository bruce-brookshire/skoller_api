defmodule Classnavapi.Repo.Migrations.CreateClasses do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :name, :string
      add :number, :string
      add :crn, :string
      add :credits, :string
      add :location, :string
      add :meet_days, :string
      add :grade_scale, :string
      add :meet_start_time, :time
      add :meet_end_time, :time
      add :seat_count, :integer
      add :class_start, :date
      add :class_end, :date
      add :class_type, :string
      add :is_ghost, :boolean, default: false, null: false
      add :is_enrollable, :boolean, default: false, null: false
      add :is_editable, :boolean, default: false, null: false
      add :is_syllabus, :boolean, default: false, null: false
      add :professor_id, references(:professors, on_delete: :nothing)
      add :class_period_id, references(:class_periods, on_delete: :nothing)
      add :class_status_id, references(:class_statuses, on_delete: :nothing)

      timestamps()
    end

    create index(:classes, [:professor_id])
    create index(:classes, [:class_period_id])
    create index(:classes, [:class_status_id])
  end
end
