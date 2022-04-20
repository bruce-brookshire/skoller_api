defmodule Skoller.Repo.Migrations.CreateCancellationReasons do
  use Ecto.Migration

  def change do
    Skoller.Enum.CancellationReasonTitle.create_type
    create table(:cancellation_reasons) do
      add :title, Skoller.Enum.CancellationReasonTitle.type()
      add :description, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

  end
end
