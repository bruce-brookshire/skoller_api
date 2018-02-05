defmodule Classnavapi.Repo.Migrations.AddDataToChangeRequests do
  use Ecto.Migration

  def change do
    alter table(:class_change_requests) do
      add :data, :map
      add :user_id, references(:users, on_delete: :nothing)
    end

    create index(:class_change_requests, [:user_id])
  end
end
