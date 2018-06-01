defmodule Skoller.Repo.Migrations.CreateUserReports do
  use Ecto.Migration

  def change do
    create table(:user_reports) do
      add :context, :string
      add :note, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :is_complete, :boolean, default: false, null: false
      add :reported_by, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:user_reports, [:user_id])
    create index(:user_reports, [:reported_by])
  end
end
