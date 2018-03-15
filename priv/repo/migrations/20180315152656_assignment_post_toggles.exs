defmodule Classnavapi.Repo.Migrations.AssignmentPostToggles do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :is_assign_post_notifications, :boolean, default: true, null: false
    end
  end
end
