defmodule Skoller.Repo.Migrations.CreateUserReports do
  use Ecto.Migration

  def change do
    create table(:user_reports) do
      add :context, :string
      add :note, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:user_reports, [:user_id])
  end
end
