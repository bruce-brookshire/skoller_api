defmodule Skoller.Repo.Migrations.AddUserIdToDocs do
  use Ecto.Migration

  def change do
    alter table(:docs) do
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
