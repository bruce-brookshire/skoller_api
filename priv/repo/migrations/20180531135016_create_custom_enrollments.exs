defmodule Skoller.Repo.Migrations.CreateCustomEnrollments do
  use Ecto.Migration

  def change do
    create table(:custom_enrollments) do
      add :custom_enrollment_link_id, references(:custom_enrollment_links, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:custom_enrollments, [:custom_enrollment_link_id])
    create index(:custom_enrollments, [:student_id])
    create unique_index(:custom_enrollments, [:custom_enrollment_link_id, :student_id], name: :unique_link_usage_index)
  end
end
