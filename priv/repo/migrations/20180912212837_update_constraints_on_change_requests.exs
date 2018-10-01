defmodule Skoller.Repo.Migrations.UpdateConstraintsOnChangeRequests do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop constraint("class_change_requests", "class_change_requests_user_id_fkey")
    alter table(:class_change_requests) do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end
    drop constraint("class_student_requests", "class_student_requests_user_id_fkey")
    alter table(:class_student_requests) do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end
    drop constraint("class_help_requests", "class_help_requests_user_id_fkey")
    alter table(:class_help_requests) do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
