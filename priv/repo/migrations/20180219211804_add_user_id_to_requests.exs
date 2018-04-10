defmodule Skoller.Repo.Migrations.AddUserIdToRequests do
  use Ecto.Migration

  def change do
    alter table(:class_help_requests) do
      add :user_id, references(:users, on_delete: :nothing)
    end

    alter table(:class_student_requests) do
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
