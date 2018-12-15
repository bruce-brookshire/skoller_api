defmodule Skoller.Repo.Migrations.CreateEmailLogs do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:email_logs) do
      add :email_type_id, references(:email_types, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:email_logs, [:email_type_id])
    create index(:email_logs, [:user_id])
  end
end
