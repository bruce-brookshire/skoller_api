defmodule Classnavapi.Repo.Migrations.CreateClassIssues do
  use Ecto.Migration

  def change do
    create table(:class_issues) do
      add :note, :string
      add :class_id, references(:classes, on_delete: :nothing)
      add :class_issue_status_id, references(:class_issue_statuses, on_delete: :nothing)

      timestamps()
    end

    create index(:class_issues, [:class_id])
    create index(:class_issues, [:class_issue_status_id])
    create unique_index(:class_issues, [:class_id, :class_issue_status_id])
  end
end
