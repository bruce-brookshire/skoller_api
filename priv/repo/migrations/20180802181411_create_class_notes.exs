defmodule Skoller.Repo.Migrations.CreateClassNotes do
  use Ecto.Migration

  def change do
    create table(:class_notes) do
      add :notes, :string, size: 750
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:class_notes, [:class_id])
  end
end
