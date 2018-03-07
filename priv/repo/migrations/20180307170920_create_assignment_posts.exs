defmodule Classnavapi.Repo.Migrations.CreateAssignmentPosts do
  use Ecto.Migration

  def change do
    create table(:assignment_posts) do
      add :post, :string, size: 750
      add :assignment_id, references(:assignments, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:assignment_posts, [:assignment_id])
    create index(:assignment_posts, [:student_id])
  end
end
