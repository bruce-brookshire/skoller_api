defmodule Skoller.Repo.Migrations.CreateStudentPointTypes do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:student_point_types) do
      add :name, :string
      add :value, :integer
      add :is_one_time, :boolean, default: false, null: false

      timestamps()
    end

    create table(:student_points) do
      add :value, :integer
      add :student_id, references(:students, on_delete: :nothing)
      add :student_point_type_id, references(:student_point_types, on_delete: :nothing)

      timestamps()
    end

    create index(:student_points, [:student_id])
    create index(:student_points, [:student_point_type_id])
  end
end
