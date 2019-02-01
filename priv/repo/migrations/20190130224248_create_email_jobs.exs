defmodule Skoller.Repo.Migrations.CreateEmailJobs do
  use Ecto.Migration

  def change do
    create table(:email_jobs) do
      add :user_id, references(:users, on_delete: :nothing)
      add :email_type_id, references(:email_types, on_delete: :nothing)
      add :is_running, :boolean, default: false

      timestamps()
    end

    create index(:email_jobs, [:user_id])
    create index(:email_jobs, [:email_type_id])
  end
end
